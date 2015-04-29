#!/usr/bin/env python
import codecs
import csv
import sys
import os
SCRIPT_DIR = os.path.split(os.path.abspath(sys.argv[0]))[0]
if len(sys.argv) == 1:
    csv_filename = os.path.join(SCRIPT_DIR, 'monophyly.csv')
elif len(sys.argv) == 2:
    csv_filename = sys.argv[1]
else:
    sys.exit('Expecting just one argument: a path to a monophyly.csv file.\n')


from peyotl.sugar import taxomachine as TNRS
out = codecs.getwriter('utf-8')(sys.stdout)
with open(csv_filename, 'rb') as inp:
    reader = csv.reader(inp, delimiter=",")
    for row in reader:
        tax_name = row[0]
        ott_id = TNRS.names_to_ott_ids_perfect([tax_name])
        out.write('{}\t{}\n'.format(ott_id, tax_name))