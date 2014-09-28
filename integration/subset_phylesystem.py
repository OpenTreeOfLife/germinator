# Make a little phylesystem containing only asterales-related studies.
# The git repo can be created from the resulting directory.

import os
import subprocess

from asterales_studies import asterales_studies

local = "asterales_phylesystem"

#for (pgnum, tree) in [(152,None)]:
for (pgnum, tree) in asterales_studies:

    num_as_string = str(pgnum)
    if pgnum < 10:
        num_as_string = '0' + num_as_string
    studyid = 'pg_' + num_as_string

    lowpart = 'pg_' + num_as_string[-2:]
    dir = 'study/%s/%s' % (lowpart, studyid)

    local_dir = "%s/%s" % (local, dir)
    if not os.path.exists(local_dir):
        print "creating %s" % local_dir
        os.makedirs(local_dir)

    studyid_json = "%s.json" % (studyid)
    path = "%s/%s" % (dir, studyid_json)
    local_path = "%s/%s" % (local, path)
    print local_path

    subprocess.call(['curl',
                     '--output', local_path,
                     'https://raw.githubusercontent.com/OpenTreeOfLife/phylesystem-1/master/%s' % path])

