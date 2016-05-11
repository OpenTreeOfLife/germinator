# lose a point if no inference method specified

import sys, codecs, csv
from peyotl.phylesystem.phylesystem_umbrella import Phylesystem
from peyotl.nexson_syntax import extract_tree_nexson

def write_tree_list(outpath):
    conflict_analyses = read_conflict_analyses()
    trees_in_synthesis = read_synthesis_list()
    taxa_in_synthesis = read_synthesis_taxa()
    phylesystem = Phylesystem()
    study_count = 0
    tree_count = 0
    preferred_count = 0
    table = []
    for study_id, nexson in phylesystem.iter_study_objs():
        study_count += 1
        nexml_el = nexson[u'nexml']
        n_intended = 1
        not_intended = nexml_el.get(u'^ot:notIntendedForSynthesis')
        if not_intended == True:
            n_intended = 0
        else:
            n_intended = 2
        candidates = nexml_el.get(u'^ot:candidateTreeForSynthesis')
        if candidates == None: candidates = []
        tid_tree_otug = extract_tree_nexson(nexson, tree_id=None)
        for (tree_id, tree, otu_group) in tid_tree_otug:
            tree_count += 1
            row = Row()

            # otu_group = otu_groups[ogi]['otuById']
            long_id = '%s@%s' % (study_id, tree_id)
            row.id = long_id

            row.n_intended = n_intended  # per study

            if len(candidates) == 0: # No selection(s) made
                if len(tid_tree_otug) == 1:
                    n_preferred = 2    # Only one tree; use it
                else:
                    n_preferred = 1    # More than one tree; decision required
            else:
                if tree_id in candidates:
                    preferred_count += 1
                    n_preferred = 2    # This is a preferred tree; use it
                else:
                    n_preferred = 0    # Not preferred, another is; do not use
            row.n_preferred = n_preferred

            ctype = tree.get('^ot:curatedType')
            n_ctype = 0
            if ctype != None and ctype != '':
                n_ctype = 1
            row.n_ctype = n_ctype

            # whether a curator has confirmed the root
            root = tree.get('^ot:specifiedRoot')
            root_confirmed = 0
            if root != None and root != '':
                root_confirmed = 1
            row.root_confirmed = root_confirmed

            row.n_synth = 1 if long_id in trees_in_synthesis else 0

            ingroup_node_id = tree.get('^ot:inGroupClade')
            row.n_ingroup = (1 if (ingroup_node_id != None) else 0)

            (row.tip_count, row.ott_count, row.new_count) = \
                examine_tree(tree, otu_group, ingroup_node_id, taxa_in_synthesis)

            row.conflict_count = 0
            row.resolve_count = 0
            analysis = conflict_analyses.get(long_id)
            if analysis != None:
                row.conflict_count = int(analysis[1])
                row.resolve_count = int(analysis[2])

            row.score = ((row.new_count + row.resolve_count) -
                         (row.conflict_count * 20) +
                         (row.n_ingroup * 10) +
                         (row.n_preferred * 50) +
                         (row.n_intended * 100))

            table.append(row)
            if tree_count % 500 == 0:
                print tree_count, long_id, ctype
    table.sort(key=lambda row:(-row.score,
                               row.n_intended == 0,   # whether intended for synthesis
                               -row.n_preferred,   # whether preferred
                               -row.n_ingroup,   # whether ingroup is designated
                               row.conflict_count,    # number of synth tree conflicts
                               -row.new_count,   # number of OTUs mapped to OTT
                               -row.n_ctype,   # whether there's a 'curated type'
                               -row.tip_count,   # total number of tips (for comparison)
                               ))
    with codecs.open(outpath, 'w', encoding='utf-8') as outfile:
        writer = csv.writer(outfile)
        writer.writerow(['tree', 'intended', 'preferred', 'has ingroup',
                         'has method', 'root confirmed', 'in synth', '#tips',
                         '#mapped', '#new', '#resolved', '#conflicts',
                         'score'])
        for row in table:
            writer.writerow([row.id, row.n_intended, row.n_preferred,
                             row.n_ingroup, row.n_ctype,
                             row.root_confirmed, row.n_synth,
                             row.tip_count, row.ott_count,
                             row.new_count,
                             row.resolve_count,
                             row.conflict_count,
                             row.score])
    print 'studies:', study_count
    print 'trees:', tree_count
    print 'preferred:', preferred_count

class Row:
    def __init__(self):
        return

# this includes the outgroup, for now - fix somehow

def examine_tree(tree, otu_group, ingroup_node_id, taxa_in_synthesis):
    edges = tree['edgeBySourceId']
    nodes = tree['nodeById']
    tip_count = 0
    ott_ids = {}
    new_ids = {}
    for node_id in nodes:
        outgoing_edges = edges.get(node_id)
        if outgoing_edges is None:
            tip_count += 1
            node = nodes[node_id]
            otu_id = node.get('@otu')
            # should never be None, but sometimes is
            if otu_id != None:
                otu = otu_group[otu_id]
                ott_id = otu.get('^ot:ottId')   # int
                if ott_id != None:
                    ott_ids[ott_id] = True
                    if not ott_id in taxa_in_synthesis:
                        new_ids[ott_id] = True
    return (tip_count, len(ott_ids), len(new_ids))

def read_conflict_analyses():
    conflict_analyses = {}
    with open('work/conflict.csv', 'r') as infile:
        reader = csv.reader(infile)
        reader.next()
        for row in reader:
            # row = [treeid, new, conflicted, resolved]
            conflict_analyses[row[0]] = row
    return conflict_analyses

def read_synthesis_list():
    trees_in_synthesis = {}
    with open('work/synthesis_tree_list.csv', 'r') as infile:
        reader = csv.reader(infile)
        reader.next()
        for row in reader:
            trees_in_synthesis[row[0]] = True
    return trees_in_synthesis

def read_synthesis_taxa():
    ids = {}
    with open('work/taxa_in_synthesis.txt', 'r') as infile:
        for line in infile:
            ids[int(line.strip())] = True
    print len(ids), 'synthesis taxa'
    return ids

write_tree_list(sys.argv[1])
