# Some class and method names borrowed from peyotl/nexson_proxy.py

import sys, os
from org.opentreeoflife.taxa import Taxonomy

def write_ids(tree, dest):
    with open(dest, 'w') as outfile:
        for node in tree.taxa():
            if node.id != None:
                outfile.write('%s\n' % node.id)

def load_tree(path):
    tree = Taxonomy.getTaxonomy(path, 'ott')
    count = 0
    for id in tree.allIds():
        count += 1
    print count, 'ids'
    return tree

write_ids(load_tree(sys.argv[1]), sys.argv[2])
