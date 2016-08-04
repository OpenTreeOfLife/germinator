# Parses the trees_report.csv output from trees_report.py to extract
# trees with certain properties

import pandas as pd
import argparse

def fraction_mapped(row):
    ntips = row['#tips']
    nmapped = row['#mapped']
    fmapped = round(nmapped/float(ntips),2)
    return fmapped

def sufficiently_curated(frame):
    curated = frame[
        #(frame['preferred']==1) &
        (frame['has ingroup']==1) &
        (frame['root confirmed']==1)
    ]
    return curated

def get_high_priority_trees(frame,mapped,conflicts,new):
    high_priority = frame[
        (frame['frac_map']>mapped) &
        (frame['#conflicts']<conflicts) &
        (frame['#new']>new)
    ]
    return high_priority

def split_tree_string(row):
    fields = row[0].split('@')
    print "study {s}, tree {t}".format(s=fields[0],t=fields[1])
    return fields

if __name__ == "__main__":
    # get command line argument (nstudies to import)
    parser = argparse.ArgumentParser(description='extract high priority trees')
    parser.add_argument('inputfile',
        help='path to the trees_report.csv file'
        )
    parser.add_argument('-c',
        dest='max_conflict',
        type=int,
        default=10,
        help='keep only trees with fewer conflicting nodes (default=10)'
        )
    parser.add_argument('-m',
        dest='min_mapped',
        type=float,
        default=0.5,
        help='keep only trees with higher fraction of mapped tips (default=0.5)'
        )
    parser.add_argument('-n',
        dest='min_new_otus',
        type=int,
        default=20,
        help='keep only trees that add more new OTUS (default=20)'
        )
    args = parser.parse_args()

    # read input file
    df = pd.read_csv(args.inputfile)
    print "read {n} trees".format(n=len(df.index))

    # get trees that are sufficently curated
    curated = sufficiently_curated(df)
    print "{n} trees are sufficently curated".format(n=len(curated.index))
    curated.to_csv('curated_trees.csv',index=False)

    # get just the trees not in synth, and drop some columns for simplicity
    not_in_synth = curated[
        (curated['in synth']==0)
    ].drop([
        'in synth','has ingroup','score',
        'has method','intended','root confirmed'
        ],1)
    print "{n} curated trees not in synthesis".format(n=len(not_in_synth))

    # add a column for fraction of otus mapped
    not_in_synth.loc[:,'frac_map']=not_in_synth.apply(
        lambda row: fraction_mapped(row),axis=1
    )

    high_priority = get_high_priority_trees(
        not_in_synth,
        args.min_mapped,
        args.max_conflict,
        args.min_new_otus
        )

    print "{t} curated trees with:\n\tfraction mapped>{m}\n\tconflict<{c}\n\tnew taxa>{n}".format(
        m=args.min_mapped,
        c=args.max_conflict,
        n=args.min_new_otus,
        t=len(high_priority.index)
    )

    #print high_priority
    #high_priority.apply(lambda row: split_tree_string(row),axis=1)
    print "printing results to high_priority.csv"
    #print high_priority[['tree','#tips','#new','#mapped','#conflicts','#resolved']]
    high_priority.to_csv('high_priority.csv',index=False,columns=['tree','#tips','#new','#mapped','#conflicts','#resolved'])
