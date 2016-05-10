import pandas as pd
import argparse

def fraction_mapped(row):
    ntips = row['#tips']
    nmapped = row['#mapped']
    fmapped = round(nmapped/float(ntips),2)
    return fmapped

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

    df = pd.read_csv(args.inputfile)
    print "read {n} trees".format(n=len(df.index))

    # get just the trees not in synth, and drop some columns we don't
    # care about right now
    not_in_synth = df[
        (df['in synth']==0)
    ].drop([
        'in synth','has ingroup','score',
        'has method','intended','root confirmed'
        ],1)
    print "{n} trees not in synthesis".format(n=len(not_in_synth))

    not_in_synth.loc[:,'frac_map']=not_in_synth.apply(
        lambda row: fraction_mapped(row),axis=1
    )

    high_priority = get_high_priority_trees(
        not_in_synth,
        args.min_mapped,
        args.max_conflict,
        args.min_new_otus
        )

    print "{t} trees with:\n\tfraction mapped>{m}\n\tconflict<{c}\n\tnew taxa>{n}".format(
        m=args.min_mapped,
        c=args.max_conflict,
        n=args.min_new_otus,
        t=len(high_priority.index)
    )

    #high_priority.apply(lambda row: split_tree_string(row),axis=1)
    #print high_priority[['tree','#tips','#new','#mapped','#conflicts','#resolved']]
