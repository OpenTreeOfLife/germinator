''' Basic script to retreive a count of OTUs from all studies in synthesis'''

import requests
import json
import time
import timeit
import os.path
import argparse


# Overview:
# Grabs the files via API
# Parses the adding OTUS to lists
# Keeps a unique set
# Counts and returns those values in JSON file
# Peter E. Midford 2014, derived from code by Lyndon Coghill


def _decode_list(data):
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


def _decode_dict(data):
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


DATE_FORMAT = '%Y-%m-%dT%HZ'


def save_results_to_json(out_name, new_result, results):
    """adds new_result to the results, keyed by the current time as parsed
    by DATE_FORMAT and saves the results to the file specified by out_name"""
    datestamp = time.strftime(DATE_FORMAT)
    results[datestamp] = new_result
    with open(out_name, 'w') as jsonfile:
        json.dump(results, jsonfile)


def parse_synth_study_ids(synthesis_list):
    """parses the return from getSynthesisSourceList, returns
    list of study ids """
    synth_study_list = []
    for study in synthesis_list['study_list']:
        study_id = study['study_id']
        if 'taxonomy' not in study_id:  # exclude 'taxonomy'
            prefix = study_id.split("_")[0]
            if prefix not in ["ot", "pg"]:
                study_id = "pg_" + str(study_id)
            synth_study_list.append(study_id)
    return synth_study_list


def get_synth_study_list(api_url):
    '''queries for list of synthesis studies'''
    url = "%s/tree_of_life/about" % api_url
    synth_response = requests.post(url,
                                   headers={'content-type':
                                            'application/json'},
                                   params={'study_list': 'true'})
    synthesis_list = json.loads(synth_response.text, object_hook=_decode_dict)
    return parse_synth_study_ids(synthesis_list)


def load_study_json(study, study_api_url):
    """returns NexSON for the study identified by 'study' as parse json"""
    url = '%s%s/' % (study_api_url, study)
    response = requests.get(url)
    return json.loads(response.text, object_hook=_decode_dict)


def get_remote_otus(json_data):
    '''parses the nexson for a study to extract the OTU ids'''
    otus = []
    if 'data' in json_data:
        for otu in json_data['data']['nexml']['otus']['otu']:
            otus.append(otu['@id'])
        return otus
    else:
        return []

DEFAULT_OUTPUT = 'synthesis.json'
DEFAULT_SERVER = 'http://api.opentreeoflife.org/'


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
    if not server.startswith('http://'):
        server = 'http://' + server
    if not server.endswith('/'):
        server = server + '/'
    api_url = server + 'v2/'
    study_api_url = server + 'v2/study/'
    old_data = load_old_results_json(filename)
    start_time = timeit.default_timer()  # used to calc run time
    # reported studies
    raw_study_list = get_synth_study_list(api_url)  

    all_synth_otus = []
    unique_synth_otus = []
    synth_study_list = []
    for study_id in raw_study_list:
        json_study = load_study_json(study_id, study_api_url)
        otus = get_remote_otus(json_study)
        if len(otus) > 0:
            synth_study_list.append(study_id)
        for otu_id in otus:
            all_synth_otus.append(otu_id)

    unique_synth_otus = set(all_synth_otus)  # keep unique values in synth otus

    # process it all, and save it to to a json file
    stop_time = timeit.default_timer()

    results = {}
    results['unique_OTU_count'] = len(unique_synth_otus)
    results['total_OTU_count'] = len(all_synth_otus)
    results['study_count'] = len(synth_study_list)
    results['reported_study_count'] = len(raw_study_list)
    results['run_time'] = stop_time - start_time

    save_results_to_json(filename, results, old_data)


if __name__ == "__main__":
    process()
