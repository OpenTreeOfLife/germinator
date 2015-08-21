''' Basic script to retreive a count of OTUs from all studies in synthesis'''

import requests
import json
import time
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


def parse_synth_query_results(synthesis_list):
    """parses the return from getSynthesisSourceList, returns
    list of study ids """
    synth_study_list = []
    for study in synthesis_list['study_list']:
        study_id = study['study_id']
        tree_id = study['tree_id']
        if 'taxonomy' not in study_id:  # exclude 'taxonomy'
            prefix = study_id.split("_")[0]
            if prefix not in ["ot", "pg"]:
                study_id = "pg_" + str(study_id)
            synth_study_list.append((study_id, tree_id))
    return synth_study_list


def get_synth_tree_list(api_url):
    '''queries for list of synthesis trees'''
    url = "%s/tree_of_life/about" % api_url
    synth_response = requests.post(url,
                                   headers={'content-type':
                                            'application/json'},
                                   params={'study_list': 'true'})
    synthesis_list = json.loads(synth_response.text, object_hook=_decode_dict)
    return parse_synth_query_results(synthesis_list)


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


def get_ott_version(study_api_url):
    """returns (as a string) the version id for ott (taxonomy)
    that the current synthetic tree was built with"""
    url = '%sgraph/about/' % study_api_url
    response = requests.post(url,
                             headers={'content-type': 'application/json'})
    graph_info = json.loads(response.text, object_hook=_decode_dict)
    return str(graph_info['graph_taxonomy_version'])


def get_tip_count(study_api_url):
    """returns the number of tips in the tree"""
    url = '%stree_of_life/about/' % study_api_url
    response = requests.post(url,
                             headers={'content-type': 'application/json'})
    tree_info = json.loads(response.text, object_hook=_decode_dict)
    return str(tree_info['num_tips'])

DEFAULT_OUTPUT = 'synthesis.json'
DEFAULT_SERVER = 'http://api.opentreeoflife.org/v2/'

USER_PROMPT = "Enter a version string for the current synthesis build: "


def getargs():
    """reads command-line arguments"""

    filename = DEFAULT_OUTPUT
    server = DEFAULT_SERVER
    synthesis_version = ''
    parser = argparse.ArgumentParser()
    parser.add_argument('-s', '--server',
                        help="specifies server to query as http URI")
    parser.add_argument('-f',
                        '--filename',
                        help="file with json object to receive results object")
    parser.add_argument('-v',
                        '--synthesis_version',
                        help="tag for the current synthesis version")
    args = parser.parse_args()
    if args.filename:
        filename = args.filename
    if args.server:
        server = args.server
    if args.synthesis_version:
        synthesis_version = args.synthesis_version
    else:
        synthesis_version = raw_input(USER_PROMPT)
    return server, filename, synthesis_version


def process():
    '''
    Generalized API locations in case they change in the future.
    Though the functions may require minor tweaks if there are changes
    '''

    server, filename, syn_version = getargs()
    if not server.startswith('http://'):
        server = 'http://' + server
    if not server.endswith('/'):
        server = server + '/'
    api_url = server + 'v2/'
    study_api_url = server + 'v2/study/'
    old_data = load_old_results_json(filename)

    # reported studies
    raw_tree_list = get_synth_tree_list(api_url)

    all_synth_otus = []
    unique_synth_otus = []
    synth_study_list = []
    for (study_id, tree_id) in raw_tree_list:
        json_study = load_study_json(study_id, study_api_url)
        otus = get_remote_otus(json_study)
        if len(otus) > 0:
            synth_study_list.append(study_id)
        for otu_id in otus:
            all_synth_otus.append(otu_id)

    unique_synth_otus = set(all_synth_otus)  # keep unique values in synth otus

    results = {}
    results['total_OTU_count'] = len(all_synth_otus)
    results['tree_count'] = len(raw_tree_list)
    results['OTT_version'] = get_ott_version(api_url)
    results['tip_count'] = int(get_tip_count(api_url))
    results['version'] = syn_version
    save_results_to_json(filename, results, old_data)


if __name__ == "__main__":
    process()
