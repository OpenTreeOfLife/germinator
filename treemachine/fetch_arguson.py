#!/usr/bin/env python
import requests
import gzip
import json
import time
import sys
import os
ZIP = True
FIRST_DOWNLOAD = True
SLEEP_INTERVAL = 5
def _debug(msg):
    sys.stderr.write('fetch_arguson.py: ')
    sys.stderr.write(msg)
    sys.stderr.write('\n')

def fp_for_node_id(node_id):
    sn = str(node_id)
    while len(sn) < 4:
        sn = '0' + sn
    thou_hund, tens_units = sn[-4:-2], sn[-2:]
    if ZIP:
        f = 'cache/{th}/{tu}/{n}.json.gz'
    else:
        f = 'cache/{th}/{tu}/{n}.json'
    return f.format(th=thou_hund, tu=tens_units, n=node_id)

def fetch_json(node_id):
    global FIRST_DOWNLOAD
    url = 'https://devapi.opentreeoflife.org/treemachine/v1/getSyntheticTree'
    headers = {'Content-type': 'application/json',}
    data = {'treeID': 'otol.draft.22',
            'format': 'arguson',
            'maxDepth': 3,
            'subtreeNodeID': str(node_id)}
    _debug('downloading {}'.format(node_id))
    if FIRST_DOWNLOAD:
        FIRST_DOWNLOAD = False
    else:
        time.sleep(SLEEP_INTERVAL)
    response = requests.post(url, headers=headers, data=json.dumps(data))
    response.raise_for_status()
    j = response.json()
    response.close()
    return j
def read_cached(fp):
    if ZIP:
        with gzip.GzipFile(fp, 'r') as zipinf:
            return json.loads(zipinf.read())
    else:
        with open(fp, 'r') as inf:
            return json.loads(inf.read())
def cache_content(obj, fp):
    par = os.path.split(fp)[0]
    _debug('checking for {}'.format(par))
    if not os.path.isdir(par):
        os.makedirs(par)
    if ZIP:
        with gzip.GzipFile(fp, 'w') as zipout:
            zipout.write(json.dumps(obj))
    else:
        with open(fp, 'w') as out:
            out.write(json.dumps(obj, sort_keys=True, indent=2))
def get_study(node_id):
    fp = fp_for_node_id(node_id)
    _debug('cache location = {}'.format(fp))
    if os.path.exists(fp):
        _debug('cache hit')
        return read_cached(fp)
    else:
        obj = fetch_json(node_id)
        cache_content(obj, fp)
        return obj
def recursive_get_study(root_id, rec_depth=0):
    _debug('recursive_get_study {i} rec_depth = {d:d}'.format(i=root_id, d=rec_depth))
    o = get_study(root_id)
    #_debug(json.dumps(o, indent=4, sort_keys=True))
    rec_depth -= 1
    if rec_depth < 0:
        return
    for child in o.get('children', []):
        cnode_id = child.get('nodeid')
        _debug('parent {}. child {}'.format(root_id, cnode_id))
        recursive_get_study(cnode_id, rec_depth)
def main(args):
    recursion_depth = 0
    try:
        node_id = args[1]
        if args[1].startswith('-r'):
            recursion_depth = int(args[1][2:])
            node_id = args[2]
        int(node_id)
    except:
        sys.exit('fetch_arguson.py: Expecting\n -r# STUDY_ID\nor\n  STUDY_ID\n' \
                 'with STUDY_ID begin numeric and # representing the recursion depth\n')
    recursive_get_study(node_id, recursion_depth)

if __name__ == '__main__':
    main(sys.argv)

