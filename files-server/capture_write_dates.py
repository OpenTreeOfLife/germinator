# Get write dates for all files in a directory D, and put them
# in a JSON file as D/.write_dates.json

import sys, os, datetime, json

dirname = sys.argv[1]

if '.git' in dirname:
    sys.exit(0)

dates = {}

for f in os.listdir(dirname):
    path = os.path.join(dirname, f)
    s = os.stat(path)
    t = s.st_mtime
    d = datetime.datetime.utcfromtimestamp(t)
    ymd = '%04d-%02d-%02d' % d.isocalendar()
    dates[f] = {'timestamp': t, 'date': ymd, 'size': s.st_size,
                'directory': os.path.isdir(path)}

path = os.path.join(dirname, '.write_dates.json')

with open(path, 'w') as outfile:
    print 'Writing %s' % path
    json.dump(dates, outfile, indent=1)
