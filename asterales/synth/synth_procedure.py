import sys
from subprocess import Popen

import general_utils
import sys

## NOTE: assumes branch 'python_synthesis_pipeline' of treemachine at the moment

################ config #####################
if len(sys.argv) <= 1:
    javapre = "java -XX:+UseConcMarkSweepGC -Xmx32g -server -jar"
    treemloc = "/home/josephwb/Work/OToL/treemachine/target/treemachine-0.0.1-SNAPSHOT-jar-with-dependencies.jar"
    basedir = "/home/josephwb/Desktop/python_synth/Asterales/"
    otloc = basedir + "ott2.9draft12/" # where is ott?
    otceteraloc = "/home/josephwb/Work/OToL/otcetera/supertree/" # supertree dir
    synthottid = "1042120" # cellular organisms, Asterales, etc.
    dbname = basedir + "Life_ottv2.9draft12.db"
    synthtree = basedir + "Life_ottv2.9draft12_synth.tre"
elif len(sys.argv) == 9:
    javapre = sys.argv[1]       # java command (including -jar)
    print 'java =', javapre
    treemloc = sys.argv[2]      # treemachine .jar
    basedir = sys.argv[3]       # not sure.  dir that contains this .py file.  ends in /
    otloc = sys.argv[4]         # location of taxonomy (ends in /)
    otceteraloc = sys.argv[5]   # {root of otcetera repo clone}/supertree/
    synthottid = sys.argv[6]    # id of root taxon
    dbname = sys.argv[7]        # where to put the neo4j db
    synthtree = sys.argv[8]     # where to put the .tre file
else:
    print 'arg count'
    sys.exit(1)

## ranked study lists:
#from plants import studytreelist as plantslist
#from metazoa import studytreelist as metalist
#from fungi import studytreelist as fungilist
#from safe_microbes import studytreelist as microbelist
from asterales import studytreelist as asteraleslist

studytreelist = []
#studytreelist.extend(plantslist)
#studytreelist.extend(metalist)
#studytreelist.extend(fungilist)
#studytreelist.extend(microbelist)
studytreelist.extend(asteraleslist)

#############################################

# the following will all be created (or overwritten)
subsettax = basedir + "subset_taxonomy-ott" + synthottid + ".tsv"
subsettaxtree = basedir + "subset_taxonomy-ott" + synthottid + ".tre"
studyloc = basedir + "Source_nexsons/" # only overwritten if download = true
trloc = basedir + "Processed_newicks/"
ranklist = basedir + "tree-ranking.txt"
subprobs = basedir + "subprobs"
processedsubprobs = basedir + "Processed_subprobs"

print "loading synthottid:",synthottid
print "loading " + str(len(studytreelist)) + " studies:", studytreelist


## phase 1: get data, initialize db, format newicks for otcetera decomposition
# get nexsons
download = False # set to False if you already have a set of nexsons and do not want fresher copies
if download:
    general_utils.get_all_studies_opentreeapi(studytreelist, studyloc)
else:
    print "\nAssuming all studies have already been downloaded to:", studyloc

# subset taxonomy
general_utils.subset_taxonomy(synthottid, otloc, subsettax)

# generate taxonomy newick (used by otcetera below)
general_utils.get_taxonomy_newick(treemloc, javapre, subsettax, subsettaxtree)

# initialize db
general_utils.init_taxonomy_db(treemloc, javapre, dbname, subsettax, otloc, basedir)

# process nexsons
general_utils.process_nexsons(studytreelist, studyloc, javapre, treemloc, dbname, trloc)

## phase 2: decomposition
general_utils.generate_tree_ranking(studytreelist, trloc, ranklist)
general_utils.set_symlinks(otceteraloc, ranklist, trloc, subsettaxtree, basedir)
general_utils.run_decomposition(basedir, otceteraloc, subprobs)

## phase 3: load, synthesis, extract
# put subprobs into format expected by treemachine
general_utils.format_subprobs(treemloc, javapre, subprobs, processedsubprobs)
general_utils.load_subprobs(treemloc, javapre, dbname, processedsubprobs, basedir)

# do it already!
general_utils.run_synth(treemloc, javapre, dbname, processedsubprobs, synthottid, basedir)
general_utils.extract_tree(treemloc, javapre, dbname, synthottid, basedir, synthtree)

## other commands: make archive, send to dev, etc. not necessary here
