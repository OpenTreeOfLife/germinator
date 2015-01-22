#!/bin/sh

. /home/opentree/venv/bin/activate

cd /home/opentree/statistics

python phylesystem_stats.py -f otstats/phylesystem.json -s api.opentreeoflife.org

rsync -e "ssh -i $HOME/.ssh/id_statistics_push" -ptv $HOME/statistics/otstats/phylesystem.json opentree@tree.opentreeoflife.org:/statistics

