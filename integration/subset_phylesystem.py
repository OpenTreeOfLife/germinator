# Make a little phylesystem containing only asterales-related studies.
# The git repo can be created from the resulting directory.

import os
import subprocess

from asterales_studies import asterales_studies

dirname = "asterales_phylesystem/study"

for (pgnum, tree) in asterales_studies:

    num_as_string = str(pgnum)
    if pgnum < 10:
        num_as_string = '0' + num_as_string
    studyid = 'pg_' + num_as_string

    lowpart = 'pg_' + num_as_string[-2:]

    test_dir = "%s/%s/%s" % (dirname, lowpart, studyid)
    if not os.path.exists(test_dir):
        print "creating %s" % test_dir
        os.makedirs(test_dir)

    studyid_json = "%s.json" % (studyid)

    test_path = "%s/%s" % (test_dir, studyid_json)
    print test_path

    subprocess.call(['curl', '--output', test_path, 'http://api.opentreeoflife.org/v2/study/%s' % studyid_json])

