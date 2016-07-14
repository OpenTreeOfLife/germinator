import sys, os, csv, json

repo_dir = '../repo'              # directory containing repo clones

# Study/tree ids in a collection

def collection_treespecs(path):
    with open(path, 'r') as infile:
        collection_json = json.load(infile)
        return map(lambda coll: (coll[u'studyID'], coll[u'treeID']),
                   collection_json[u'decisions'])

synthesis_treespecs = []        # rank order
trees_in_synthesis = {}

def read_synthesis_collections(collections_repo):
    if len(synthesis_treespecs) > 0: return
    for collection_name in ['fungi',
                            'safe-microbes',
                            'metazoa',
                            'plants']:
        path = os.path.join(collections_repo, 'collections-by-owner/opentreeoflife', collection_name + '.json')
        print 'reading', path
        for treespec in collection_treespecs(path):
            synthesis_treespecs.append(treespec)
            trees_in_synthesis[treespec] = True

def in_synthesis(study_id, tree_id):
    if len(trees_in_synthesis) == 0:
        read_synthesis_collections()
    treespec = (study_id, tree_id)
    if treespec in trees_in_synthesis:
        return trees_in_synthesis[treespec]
    else:
        return False

collections_repo = sys.argv[1]
outpath = sys.argv[2]

read_synthesis_collections(collections_repo)

with open(outpath, 'w') as outfile:
    writer = csv.writer(outfile)
    writer.writerow(['tree'])
    for (studyid, treeid) in synthesis_treespecs:
        writer.writerow(['%s@%s' % (studyid, treeid)])
