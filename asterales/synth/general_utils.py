## mostly refactored stuff from gcmdr ###

import urllib2, re, os
from shutil import rmtree
from subprocess import Popen, call


def get_study_opentreeapi(studyid, studyloc):
    call = "http://api.opentreeoflife.org/v2/study/" + studyid
    req = urllib2.Request(call)
    res = urllib2.urlopen(req)
    fl = open(studyloc + "/" + studyid, "w")
    fl.write(res.read())
    fl.close()


def get_all_studies_opentreeapi(studytreelist, studyloc):
    if not os.path.exists(studyloc):
        print "Creating directory " + studyloc
        os.makedirs(studyloc)
    for i in studytreelist:
        a = i.split("_")
        studyid = "_".join(a[:-1])
        print "Downloading studyid " + studyid + " to " + studyloc
        get_study_opentreeapi(studyid, studyloc)


# prune unmapped and duplicated taxa
def process_nexsons(studytreelist, studyloc, javapre, treemloc, graphdb, outd):
    if not os.path.exists(outd):
        print "Creating directory " + outd
        os.makedirs(outd)
    else:
        print "Overwriting directory " + outd
        from shutil import rmtree
        rmtree(outd)
        os.makedirs(outd)
    for i in studytreelist:
        a = i.split("_")
        studyid = "_".join(a[:-1])
        treeid = a[2]
        cmd = javapre.split(" ")
        cmd.append(treemloc)
        cmd.append("processtree")
        study = studyloc + studyid
        cmd.append(study)
        cmd.append(treeid)
        cmd.append(graphdb)
        cmd.append(outd)
        print " ".join(cmd)
        pr = Popen(cmd).wait()
        print "\nProcessing studyid " + studyid + " and treeid: " + treeid


# needed for processing nexsons (defines valid taxa), and synthesis
def init_taxonomy_db(treemloc, javapre, db, taxfile, otloc, basedir):
    print "\nInitializing taxonomy DB"
    taxversion = get_taxonomy_version(otloc)
    synfile = otloc + "synonyms.tsv"
    cmd = javapre.split(" ")
    cmd.append(treemloc)
    cmd.append("inittax")
    cmd.append(taxfile)
    cmd.append(synfile)
    cmd.append(taxversion)
    cmd.append(db)
    pr = Popen(cmd).wait()


def get_taxonomy_version(otloc):
    tv = open(otloc + "version.txt", "r").read().split("\n")
    return tv[0]


# filter taxonomy 1) restrict to target, 2) exclude 'dubious' taxa
def subset_taxonomy(target, otloc, outtax):
    tflags = ["major_rank_conflict", "major_rank_conflict_inherited", "environmental",
    "unclassified_inherited", "unclassified", "viral", "barren", "not_otu", "incertae_sedis",
    "incertae_sedis_inherited", "extinct_inherited", "extinct", "hidden", "unplaced", "unplaced_inherited",
    "was_container", "merged", "inconsistent", "hybrid"]
    intax = otloc + "taxonomy.tsv"
    print "\nSubsetting taxonomy to target taxon:", target
    infile = open(intax, "r")
    outfile = open(outtax, "w")

    count = 0
    pid = {} #key is the child id and the value is the parent
    cid = {} #key is the parent and value is the list of children
    nid = {}
    nrank = {}
    sid = {}
    unid = {}
    flagsp = {}
    targetid = ""
    prune = False
    for i in infile:
        spls = i.strip().split("\t|")
        tid = spls[0].strip()
        parentid = spls[1].strip()
        name = spls[2].strip()
        rank = spls[3].strip()
        nrank[tid] = rank
        nid[tid] = name
        sid[tid] = spls[4].strip()
        unid[tid] = spls[5].strip()
        flags = spls[6].strip()
        badflag = False
        if len(flags) > 0:
            for j in tflags:
                if j in flags:
                    badflag = True
                    break
            if badflag == True:
                continue
        flagsp[tid] = flags
        pid[tid] = parentid
        if tid == target or name == target:
            print "name set: " + name + "; tid: " + tid
            targetid = tid
            pid[tid] = ""
        if parentid not in cid: 
            cid[parentid] = []
        cid[parentid].append(tid)
        count += 1
        if count % 100000 == 0:
            print count
    infile.close()
    
    stack = [targetid]
    while len(stack) > 0:
        tempid = stack.pop()
        outfile.write(tempid+"\t|\t"+pid[tempid]+"\t|\t"+nid[tempid]+"\t|\t"+nrank[tempid]+"\t|\t"+sid[tempid]+"\t|\t"+unid[tempid]+"\t|\t"+flagsp[tempid]+"\t|\t\n")
        if tempid in cid:
            for i in cid[tempid]:
                if prune == True:
                    if i in cid: # is the taxon a parent?
                        stack.append(i)
                else:
                    stack.append(i)
    outfile.close()


# generate taxonomy newick for use with otcetera. labels are ottids.
def get_taxonomy_newick(treemloc, javapre, subsettax, subsettaxtree):
    print "\nGenerating taxonomy newick"
    cmd = javapre.split(" ")
    cmd.append(treemloc)
    cmd.append("converttaxonomy")
    cmd.append(subsettax)
    cmd.append(subsettaxtree)
    cmd.append("T") # labels are ottids
    pr = Popen(cmd).wait()


# from studytreelist, make sure newick exists, write tree rank list for otcetera
def generate_tree_ranking(studytreelist, trloc, outranklist):
    # loop over processed newicks and studytreelist.
    # some in the latter may not have survived processing (e.g. all tips 'dubious')
    dirListing = os.listdir(trloc)
    outfile = open(outranklist, "w")
    for i in studytreelist:
        for j in dirListing:
            if j.startswith(i):
                outfile.write(j + "\n")
    outfile.close()


# symlinks for otcetera:
# step_1: tree-ranking.txt, taxonomy.tre
# step_4: newicks
# using -sf here as make -f Makefile.synth-v3 clean does not currently clean everything
# tbd: don't need basedir any more
def set_symlinks(otceteraloc, ranklist, trloc, subsettaxtree, basedir):
    print "\nAttempting to clean any existing files"
    wd = os.getcwd()
    os.chdir(otceteraloc)
    # This yields lots of "No such file or directory" messages,
    # but they're innocuous
    cmd = ["make", "-f", "Makefile.synth-v3", "clean"]
    pr = Popen(cmd).wait()
    os.chdir(wd)
    
    print "\nSetting up symlinks for otcetera"
    call(["ln", "-sf", ranklist, otceteraloc + "step_1/tree-ranking.txt"])
    call(["ln", "-sf", subsettaxtree, otceteraloc + "step_1/taxonomy.tre"])
    
    # remove any existing symlinks (again, make clean does not purge these)
    call(["rm", "-f", otceteraloc + "step_4/ot*", otceteraloc + "step_4/pg*"])
    
    print "\nSetting up symlinks for individual newicks"
    trees = [line.rstrip('\n') for line in open(ranklist)]
    for i in trees:
        call(["ln", "-sf", trloc + i, otceteraloc + "step_4/" + i])


# run decomposition and copy results to working directory
# tbd: don't need basedir any more
def run_decomposition(basedir, otceteraloc, subprobs):
    print "\nMoving to otcetera dir: " + otceteraloc
    wd = os.getcwd()
    os.chdir(otceteraloc)
    cmd = ["make", "-f", "Makefile.synth-v3"]
    pr = Popen(cmd).wait()
    if os.path.exists(subprobs):
        print "Removing existing directory " + subprobs
        rmtree(subprobs)
    print "Copying subprobs to base dir: " + basedir
    call(["cp", "-r", otceteraloc + "step_7_scratch/export-sub-temp", subprobs])
    print "Moving back to base dir: " + basedir
    os.chdir(wd)
    

# throw out trivial subprobs (taxonomy only), format others for treemachine loading
def format_subprobs(treemloc, javapre, subprobs, processedsubprobs):
    print "\nFormatting subproblems"
    if not os.path.exists(processedsubprobs):
        print "Creating directory " + processedsubprobs
        os.makedirs(processedsubprobs)
    else:
        print "Overwriting directory " + processedsubprobs
        rmtree(processedsubprobs)
        os.makedirs(processedsubprobs)
    cmd = javapre.split(" ")
    cmd.append(treemloc)
    cmd.append("processsubprobs")
    cmd.append(subprobs)
    cmd.append(processedsubprobs)
    print cmd
    pr = Popen(cmd).wait()


def load_subprobs(treemloc, javapre, db, processedsubprobs, basedir):
    dirListing = os.listdir(processedsubprobs)
    count = 0
    iter = 0
    print "\nLoading " + str(len(dirListing)) + " subproblems into: " + db
    for t in dirListing:
        count = count + 1
        iter = iter + 1
        if iter == 100:
            iter = 0
            print count
        cmd = javapre.split(" ")
        cmd.append(treemloc)
        cmd.append("loadtrees")
        cmd.append(processedsubprobs + "/" + t)
        cmd.append(db)
        cmd.append("T")
        cmd.append("subset")
        pr = Popen(cmd).wait()


def run_synth(treemloc, javapre, db, processedsubprobs, synthottid, basedir):
    print "\nSynthesizing"
    cmd = javapre.split(" ")
    cmd.append(treemloc)
    cmd.append("synthesizedrafttreelist_ottid")
    cmd.append(synthottid)
    cmd.append("taxonomy")
    cmd.append(db)
    pr = Popen(cmd).wait()
    

# extract newick
def extract_tree(treemloc, javapre, db, synthottid, basedir, synthtree):
    print "\nExtracting tree"
    cmd = javapre.split(" ")
    cmd.append(treemloc)
    cmd.append("extractdrafttree_ottid")
    cmd.append(synthottid)
    cmd.append(synthtree)
    cmd.append(db)
    pr = Popen(cmd).wait()








