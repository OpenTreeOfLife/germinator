# Get write dates for all files in a directory D, and put them
# in a JSON file as D/.write_dates.json

import sys, os, datetime, json, argparse

dotfile = '.write_dates.json'

def capture_write_dates(dirname, refreshp):

    if '.git' in dirname:
        sys.exit(0)

    oldmeta = {}
    if not refreshp:
        if os.path.exists(dotfile):
            with open(dotfile, 'r') as infile:
                oldmeta = json.load(infile)

    newmeta = {}
    for f in os.listdir(dirname):

        if f.startswith('.') or f.endswith('~'):
            continue

        path = os.path.join(dirname, f)
        s = os.stat(path)

        if f in oldmeta:
            have = oldmeta[f]
            if have['size'] == s.st_size:
                newmeta[f] = have
                continue
            else:
                print 'File changed: %s' % f
        else:
            print 'New file: %s' % f

        t = s.st_mtime
        d = datetime.datetime.utcfromtimestamp(t)
        ymd = '%04d-%02d-%02d' % d.isocalendar()
        newmeta[f] = {'timestamp': t, 'date': ymd, 'size': s.st_size,
                    'directory': os.path.isdir(path)}

    for f in oldmeta:
        if not f in newmeta:
            print 'Carrying over metadata for: %s' % f
            newmeta[f] = oldmeta[f]

    # Write out new metadata
    path = os.path.join(dirname, dotfile)

    with open(path, 'w') as outfile:
        print 'Writing %s' % path
        json.dump(newmeta, outfile, indent=1)

if __name__ == '__main__':
    argp = argparse.ArgumentParser()
    argp.add_argument('--refresh', dest='refresh', action='store_true')
    argp.add_argument('dirname')
    args = argp.parse_args()
    capture_write_dates(args.dirname, args.refresh)

