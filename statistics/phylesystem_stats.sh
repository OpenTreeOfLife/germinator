#!/bin/sh

# parameterized script to create/update a phylesystem stats file and push to a web2py server
# parameters $1 = local folder to save stats history file
#            $2 = api url (e.g., devapi.opentreeoflife.org)
#            $3 = target host machine  (e.g., devtree.opentreeoflife.org)


. $HOME/venv/bin/activate

cd $HOME/statistics

python phylesystem_stats.py -f $1/phylesystem.json -s $2

rsync -e "ssh -i $HOME/.ssh/id_statistics_push" -ptv $HOME/statistics/devstats/phylesystem.json opentree@$3:/statistics

