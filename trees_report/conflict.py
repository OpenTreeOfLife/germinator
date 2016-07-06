# Some class and method names borrowed from peyotl/nexson_proxy.py

import sys, os, json, argparse, csv
from org.opentreeoflife.taxa import Taxonomy, Nexson, Flag
from org.opentreeoflife.conflict import ConflictAnalysis, Disposition

# Report generation

# Report on every tree in every study

def report_on_trees(study_ids, shard, refs, outfile):
    out = sys.stdout
    if outfile != '-': out = open(outfile, 'w')
    writer = start_report(refs, out)
    count = 0
    for study_id in study_ids:
        study = get_study(study_id, shard)
        if study == None: continue
        for tree in tree_iter_nexson_proxy(study):
            row = report_on_tree(tree, study, refs)
            writer.writerow(row)
            count += 1
            if count % 100 == 0: print count, row
    if outfile != '-': out.close()

def start_report(refs, out):
    writer = csv.writer(out)
    writer.writerow(tree_report_header(refs))
    return writer

# 'tree' report
# Write one row using the given csv writer summarizing how the given
# tree conflicts with taxonomy and/or synthesis.

tree_report_header_1 = ['tree']
tree_report_header_2 = ['conflicted', 'resolves']

def tree_report_header(refs):
    row = tree_report_header_1
    for ref in refs:
        row = row + tree_report_header_2
    return row

def report_on_tree(tree, study, refs):
    input = import_tree(tree, study)

    # One row per tree
    row = ['%s@%s' % (study.id, tree.tree_id)]
    for ref in refs:
        row = row + [count_conflicts(input, ref, tree.ingroup()),
                     count_resolutions(input, ref, tree.ingroup())]
    return row

def count_conflicts(input, ref, ingroup):
    analysis = ConflictAnalysis(input, ref, ingroup)
    arts = analysis.articulations(True)
    if arts == None: arts = []
    count = 0
    for art in arts:
        if art.disposition == Disposition.CONFLICTS_WITH:
            count += 1
    return count

def count_resolutions(input, ref, ingroup):
    analysis = ConflictAnalysis(input, ref, ingroup)
    arts = analysis.articulations(False)
    if arts == None: arts = []
    count = 0
    for art in arts:
        if art.disposition == Disposition.RESOLVES:
            count += 1
    return count

# Proxy object for study file in nexson format

class NexsonProxy(object):
    def __init__(self, filepath):
        self.filepath = filepath # peyotl name
        self.nexson = None
        self.reftax_otus = {}
        self.nexson_trees = {}         # tree_id -> blob
        self.preferred_trees = []
        self._tree_proxy_cache = {}

        self.nexson = Nexson.load(self.filepath)
        self._nexml_element = self.nexson[u'nexml'] # peyotl name
        self.reftax_otus = Nexson.getOtus(self.nexson) # sort of wrong
        z = self.get(u'^ot:candidateTreeForSynthesis')
        if z != None: self.preferred_trees = z
        self.id = self.get(u'^ot:studyId')

    def get(self, attribute):
        if attribute in self.nexson[u'nexml']:
            return self._nexml_element[attribute]
        else:
            return None

    # cf. peyotl _create_tree_proxy (does not always create)
    def _get_tree_proxy(self, tree_id, tree, otus_id):
        tp = self._tree_proxy_cache.get(tree_id)
        if tp is None:
            np = NexsonTreeProxy(tree, tree_id, otus_id, self)
            self._tree_proxy_cache[tree_id] = np
        return np

    def get_tree(self, tree_id):
        np = self._tree_proxy_cache.get(tree_id)
        if np is not None:
            return np
        tgd = self._nexml_element[u'treesById']
        for tg in tgd.values():
            tbid = tg[u'treeById']
            if tree_id in tbid:
                otus_id = tg[u'@otus']
                nexson_tree = tbid[tree_id]
                return self._get_tree_proxy(tree_id=tree_id, tree=nexson_tree, otus_id=otus_id)
        return None

def tree_iter_nexson_proxy(nexson_proxy): # peyotl
    '''Iterates over NexsonTreeProxy objects in order determined by the nexson blob'''
    nexml_el = nexson_proxy._nexml_element
    tg_order = nexml_el['^ot:treesElementOrder']
    tgd = nexml_el['treesById']
    for tg_id in tg_order:
        tg = tgd[tg_id]
        tree_order = tg['^ot:treeElementOrder']
        tbid = tg['treeById']
        otus_id = tg['@otus']
        for k in tree_order:
            v = tbid[k]
            yield nexson_proxy._get_tree_proxy(tree_id=k, tree=v, otus_id=otus_id)

class NexsonTreeProxy(object):
    def __init__(self, nexson_tree, tree_id, otus_id, nexson_proxy):
        self.nexson_tree = nexson_tree
        self.nexson_otus_id = otus_id
        self.tree_id = tree_id
        self._nexson_proxy = nexson_proxy
        by_id = nexson_proxy._nexml_element[u'otusById']
        if otus_id not in by_id:
            print '** otus id not found', nexson_proxy.id, tree_id, otus_id, by_id.keys()
        self._otus = by_id[otus_id][u'otuById']
    def ingroup(self):
        ingroup = self.nexson_tree.get(u'^ot:inGroupClade')
        if ingroup == '':
            return None
        else:
            return ingroup

# Marshalling arguments

# shard is the path to the root of the repository (or shard) clone

def study_id_to_path(study_id, shard):
    (prefix, number) = study_id.split('_', 1)
    if len(number) == 1:
        residue = '_' + number
    else:
        residue = number[-2:]
    return os.path.join(shard, 'study', prefix + '_' + residue, study_id, study_id + '.json')

# Load a study

single_study_cache = {'id': None, 'study': None}

def get_study(study_id, shard):
    if study_id == single_study_cache['id']:
        study = single_study_cache['study']
    else:
        single_study_cache['id'] = None
        single_study_cache['study'] = None
        study = gobble_study(study_id, shard)
        if study != None:
            single_study_cache['study'] = study
            single_study_cache['id'] = study_id
    return study

def gobble_study(study_id, phylesystem):
    filepath = study_id_to_path(study_id, phylesystem)
    # should do try/catch for file-not-found
    if not os.path.exists(filepath):
        # foo, should be using try/catch
        print '** Not found:', filepath
        return None
    return NexsonProxy(filepath)

def import_tree(tree, study):
    return Nexson.importTree(tree.nexson_tree,
                             tree._nexson_proxy.reftax_otus,
                             '%s@%s' % (study.id, tree.tree_id))

# Utilities associated with obtaining study and tree lists for reporting

# All study ids within a given phylesystem (shard)

def all_study_ids(shard):
    ids = []
    top = os.path.join(shard, 'study')
    hundreds = os.listdir(top)
    for dir in hundreds:
        if not dir.startswith('.'):
            dir2 = os.path.join(top, dir)
            if os.path.isdir(dir2):
                dirs = os.listdir(dir2)
                for study_dir in dirs:
                    dir3 = os.path.join(dir2, study_dir)
                    if os.path.isdir(dir3):
                        ids.append(study_dir)
    print len(ids), 'studies'
    return ids

# These are some asterales studies.  List is from gcmdr repo.
asterales_treespecs=[("pg_2539", "tree6294"), # Soltis et al. 2011
               ("pg_715", "tree1289"),  # Barnadesioideae
               ("pg_329", "tree324"),   # Hieracium
        #       ("pg_9", "tree1"),       # Campanulidae
               ("pg_1944", "tree3959"), # Campanulidae; replacement of 9 above
               ("pg_709", "tree1276"),  # Lobelioideae, very non monophyletic
               ("pg_41", "tree1396"),   # Feddea
               ("pg_82", "tree5792"),   # Campanula, very non monophyletic campanula
               ("pg_932", "tree1831")   # Goodeniaceae, tons of non monophyly
               ]

def get_refs(paths):
    return map(load_tree, paths)

def load_tree(path):
    tree = Taxonomy.getTaxonomy(path, 'ott')
    count = 0
    for id in tree.allIds():
        count += 1
    print count, 'ids'
    return tree

repo_dir = '../..'              # directory containing repo clones
registry_dir = os.path.join(repo_dir, 'reference-taxonomy', 'registry')

# consider comparing the "^ot:focalClade" to the induced root

if __name__ == '__main__':

    argparser = argparse.ArgumentParser(description='Play around with conflict.')

    argparser.add_argument('--out', dest='outfile', default='-')

    argparser.add_argument('--shard', dest='shard',
                           default=os.path.join(repo_dir, 'phylesystem-1'),
                           help='root directory of repository (shard) containing nexsons')
    argparser.add_argument('--ref', dest='refs', nargs='+',
                           default=os.path.join(registry_dir, 'draftversion4.tre'), # synthetic tree is a newick...
                           help='reference tree (taxonomy or synth)')
    args = argparser.parse_args()

    # refs = get_refs(args.refs, os.path.join(registry_dir, 'plants-ott29/'))
    # refs = get_refs(args.refs, os.path.join(registry_dir, 'ott2.9/'))

    report_on_trees(all_study_ids(args.shard),
                    args.shard,
                    get_refs(args.refs),
                    args.outfile)

#   /Users/jar/a/ot/repo/phylesystem-1/study/ot_31/ot_31/ot_31.json
#          ls -l ../repo/phylesystem-1/study/ot_31/ot_31/ot_31.json 


# look at u'^ot:candidateTreeForSynthesis' = list of tree ids
# look at list of trees in synthesis (from collections)
