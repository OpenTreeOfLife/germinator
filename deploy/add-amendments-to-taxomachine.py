#!/usr/bin/env python
from __future__ import print_function
import codecs
import sys
try:
    import requests
except:
    sys.exit('Use "pip install requests" to install the requests package\n')
import os
import re
import json
AMEND_PAT = re.compile(r'additions-(\d+)-\d+.json')

try:
    assert '-h' not in sys.argv
    assert '--help' not in sys.argv
    amend_dir, domain = sys.argv[1:]
    assert(os.path.isdir(amend_dir))
except:
    sys.exit('''This script will push amendments to an Open Tree of Life
taxonomy server. It is intended to be used post-deployment of a taxonomy
database. It walks through an amendments directory in reverse order (highest
new OTT Id first) until it finds an OTT Id that is already known to the
server. Then it sends the unknown amendments to the server in the order
that they were added to the taxonomy (in the original order, lowest OTT Id
first).

Expecting 2 arugments:
  first: the path to the "amendments" subirectory
     of the amendments-repo that you'd like to sync.
  second: the domain of the server to push to.

Typical usages:

  ./add-amendments-to-taxomachine.py /some/path/amendments-1/amendments api.opentreeoflife.org

Or

  ./add-amendments-to-taxomachine.py /some/path/amendments-0/amendments devapi.opentreeoflife.org

''')

tax_info_url = r'https://{}/v3/taxonomy/taxon_info'.format(domain)
push_add_url = r'https://{}/v3/taxonomy/process_additions'.format(domain)
headers = {'content-type': 'application/json'}


by_beg_id = []
for f in os.listdir(amend_dir):
    m = AMEND_PAT.match(f)
    if not m:
        print('skipping non-addition {}'.format(f))
        continue
    beg_id = int(m.group(1))
    by_beg_id.append((beg_id, os.path.join(amend_dir, f)))
by_beg_id.sort(reverse=True)


def check_for_taxon(ott_id):
    darg = '{"ott_id":' + str(ott_id) + '}'
    resp = requests.post(tax_info_url, data=darg, headers=headers)
    try:
        resp.raise_for_status()
    except:
        return False
    else:
        print(resp.json())
        return True

def push_addition_object(add_blob):
    post_blob = {'addition_document': json.dumps(add_blob)}
    post_str = json.dumps(post_blob)
    resp = requests.post(push_add_url, data=post_str, headers=headers)
    resp.raise_for_status()
    return True

to_push = []
for beg_id, fp in by_beg_id:
    if check_for_taxon(beg_id):
        print('taxon {} already in the taxonomy server. Stopping...'.format(beg_id))
        break
    to_push.append(fp)

to_push.reverse()
for fp in to_push.reverse()
    sys.stderr.write('pushing amendment {} ...\n'.format(fp))
    with codecs.open(fp, 'rU', encoding='utf-8') as inp:
        blob = json.load(inp)
    r = push_addition_object(blob)