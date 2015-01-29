#!/bin/sh

# parameterized script to create/update a synthesis stats file and push to a web2py server
# parameters $1 = local folder to save stats history file
#            $2 = api url (e.g., devapi.opentreeoflife.org)
#            $3 = target host machine  (e.g., devtree.opentreeoflife.org)


. $HOME/venv/bin/activate

cd $HOME/statistics

python synthesis_stats.py -f $1/synthesis.json -s $2

rsync -e "ssh -i $HOME/.ssh/id_statistics_push" -ptv $HOME/statistics/devstats/synthesis.json opentree@$3:/statistics
