'''Basic script to retreive a count of OTUs from all studies in phylesystem'''

import requests
import json
import time
import timeit
import os.path
import sys
import argparse


# Overview:
# Grabs the files via API
# Parses the adding OTUS to lists
# Keeps a unique set
# Counts and returns those values in JSON file
# Peter E. Midford 2014, derived from code by Lyndon Coghill 2014


def _decode_list(data):  # used for parsing out unicode
    """parses 'out' unicode from a list of data as part of json parsing"""
    result = []
    for item in data:
        if isinstance(item, unicode):
            item = item.encode('utf-8')
        elif isinstance(item, list):
            item = _decode_list(item)
        elif isinstance(item, dict):
            item = _decode_dict(item)
        result.append(item)
    return result


def _decode_dict(data):  # used to parse out unicode
    """parses 'out' unicode from a dictionary as part of json parsing"""
    result = {}
    for key, value in data.iteritems():
        if isinstance(key, unicode):
            key = key.encode('utf-8')
        if isinstance(value, unicode):
            value = value.encode('utf-8')
        elif isinstance(value, list):
            value = _decode_list(value)
        elif isinstance(value, dict):
            value = _decode_dict(value)
        result[key] = value
    return result


def load_old_results_json(in_name):
    """loads prior statistics results from existing json file named by in_name
    returns empty dict if no such file exists"""
    if os.path.isfile(in_name):
        with open(in_name, 'r') as jsonfile:
            return json.load(jsonfile, object_hook=_decode_dict)
    else:
        return {}

DATE_FORMAT = '%Y-%m-%d'


def save_results_to_json(out_name, new_result, results):
    """adds new_result to the results, keyed by the current time as parsed
    by DATE_FORMAT and saves the results to the file specified by out_name.
    Code now writes json object to tempfile first, then copies"""
    import tempfile
    import os
    datestamp = time.strftime(DATE_FORMAT)
    results[datestamp] = new_result

    tempf = tempfile.NamedTemporaryFile(delete=False, dir='.')
    with tempf as jsonfile:
        json.dump(results, jsonfile)
    os.rename(tempf.name, out_name)


def parse_synth_study_ids(synthesis_list):
    '''parses the return from getSynthesisSourceList'''
    synth_study_list = []
    for study in synthesis_list['study_list']:
        study_id = study['study_id']
        if 'taxonomy' not in study_id:  # exclude 'taxonomy'
            prefix = study_id.split("_")[0]
            if prefix not in ["ot", "pg"]:
                study_id = "pg_" + str(study_id)
            synth_study_list.append(study_id)
    return synth_study_list


def get_study_list(api_url):
    '''queries for list of all studies'''
    url = "%s/studies/find_studies" % api_url
    headers = {'content-type': 'application/json'}
    response = requests.post(url, headers=headers)
    try:
        studies = json.loads(response.text, object_hook=_decode_dict)
    except ValueError:
        print "URL {0} returned bad json {1}".format(url, response.text[0:100])
        sys.exit(2)
    study_list = [study['ot:studyId'] for study in studies['matched_studies']]
    return study_list


def load_study_json(study, study_api_url):
    """returns NexSON for the study identified by 'study' as parse json"""
    url = '%s%s/' % (study_api_url, study)
    print("url = {}".format(url))
    response = requests.get(url)
    try:
        study_json = json.loads(response.text, object_hook=_decode_dict)
    except ValueError:
        print "URL {0} returned bad json {1}".format(url, response.text[0:100])
        sys.exit(2)
    return study_json


def get_remote_otus(json_data):
    '''parses the nexson for a study to extract the OTU ids'''
    otus = []
    if 'data' in json_data:
        for otu in json_data['data']['nexml']['otus']['otu']:
            otus.append(otu['@id'])
        return otus
    else:
        # print json_data
        return []


def _is_nominated(json_data):
    """checks if study in json_data is annotated as nominated for synthesis"""
    annotations = json_data['data']['nexml']['meta']
    return _is_for_synthesis(annotations)


# not currently used
def _is_validated(study_annotations):
    """checks if the study whose annotations are in study_annotations
    passes peyotl validation without errors (warnings slip through)"""
    for ann in study_annotations:
        if '@property' in ann:
            if ann['@property'] == 'ot:annotationEvents':
                events = ann['annotation']
                for event in events:
                    if event['@id'] == 'peyotl-validator-event':
                        return event['@passedChecks']
    return False


def _is_for_synthesis(study_annotations):
    """checks if the study whose annotations are in study_annotations
    is intended for synthesis (aka nominated)"""
    for ann in study_annotations:
        if '@property' in ann:
            if ann['@property'] == 'ot:notIntendedForSynthesis':
                val = ann['$']
                if val is True:
                    return False
    return True

DEFAULT_OUTPUT = 'phylesystem.json'
DEFAULT_SERVER = 'http://devapi.opentreeoflife.org/'


def getargs():
    """reads command-line arguments"""
    filename = DEFAULT_OUTPUT
    server = DEFAULT_SERVER
    parser = argparse.ArgumentParser()
    parser.add_argument('-s', '--server',
                        help="specifies server to query as http URI")
    parser.add_argument('-f',
                        '--filename',
                        help="file with json object to receive results object")
    args = parser.parse_args()
    if args.filename:
        filename = args.filename
    if args.server:
        server = args.server
    return server, filename


def process():
    '''
    Generalized API locations in case they change in the future.
    Though the functions may require minor tweaks if there are changes
    '''

    server, filename = getargs()
    if not server.startswith('https://'):
        server = 'https://' + server
    if not server.endswith('/'):
        server = server + '/'
    api_url = server + 'v3/'

    # point where needed, but see get_remote_otus
    study_api_url = server + 'v3/studies/'

    old_data = load_old_results_json(filename)

    # Get list of all studies, and process for aotus '''

    raw_study_list = get_study_list(api_url)  # all studies
    study_list = []
    synth_nominated_list = []
    all_unique_otus = []
    all_otus = []
    all_nominated_otus = []
    for study_id in raw_study_list:
        json_study = load_study_json(study_id, study_api_url)
        otus = get_remote_otus(json_study)
        if len(otus) > 0:
            study_list.append(study_id)
            if _is_nominated(json_study):
                synth_nominated_list.append(study_id)
                all_otus.extend(otus)
                if study_id in synth_nominated_list:
                    all_nominated_otus.extend(otus)

    all_unique_otus = set(all_otus)  # keep only unique values in all otus
    total_otus = len(all_otus)
    unique_nominated_otus = set(all_nominated_otus)

    # process it all, and save it to to a json file

    results = {}
    results['unique_OTU_count'] = len(all_unique_otus)
    results['OTU_count'] = total_otus
    results['study_count'] = len(study_list)
    results['nominated_study_count'] = len(synth_nominated_list)
    results['nominated_study_OTU_count'] = len(all_nominated_otus)
    results['nominated_study_unique_OTU_count'] = len(unique_nominated_otus)
    results['reported_study_count'] = len(raw_study_list)

    save_results_to_json(filename, results, old_data)


if __name__ == "__main__":
    process()
