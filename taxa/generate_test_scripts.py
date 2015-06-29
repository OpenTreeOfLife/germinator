#!/usr/bin/env python

"""
Generate shell scripts to perform monophyly and inclusion tests from csv files.
Assumes "monophyly.csv" and "inclusions.csv" are in the present directory.
Makes the files "monophyly_tests.sh" and "inclusion_tests.sh", overwriting them
if they already exist.
"""

import sys
import os
import os.path

# using devapi for now. might make this an argument
curl_prefix = "curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H \"content-type:application/json\" -d \'{\"ott_id\":"

## monophyly tests ##
if (os.path.isfile("monophyly.csv") == False):
    print "Cannot find file 'monophyly.csv'"
    sys.exit(0)
    
infile = open("monophyly.csv","r")
outfile = open("monophyly_tests.sh","w")

outfile.write("#!/bin/bash\n\n")
outfile.write("## Test special taxonomic nodes against the synthetic tree\n\n")

for i in infile:
    spls = i.strip().split(",")
    taxon = spls[0].strip()
    ottid = spls[1].strip()
    
    outfile.write("echo -e \"\\nChecking status of \'" + taxon + "\'...\"\n")
    outfile.write(curl_prefix + ottid + "}\'\n")
    
outfile.write("\n")
infile.close()
outfile.close()
#####################

## inclusion tests ##
if (os.path.isfile("inclusions.csv") == False):
    print "Cannot find file 'inclusions.csv'"
    sys.exit(0)
infile = open("inclusions.csv","r")
outfile = open("inclusion_tests.sh","w")

outfile.write("#!/bin/bash\n\n")
outfile.write("## Test whether special taxonomic nodes are descendants of other special taxonomic nodes in the synthetic tree\n\n")

for i in infile:
    spls = i.strip().split(",")
    taxon = spls[0].strip()
    parent = spls[1].strip()
    ottid = spls[2].strip()
    
    outfile.write("echo -e \"\\nChecking inclusion of \'" + taxon + "\' in \'" + parent + "\'...\"\n")
    outfile.write(curl_prefix + ottid + ", \"include_lineage\":true}\'\n")
    
outfile.write("\n")
infile.close()
outfile.close()
#####################

