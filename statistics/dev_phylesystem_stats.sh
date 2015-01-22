#!/bin/sh

. /home/opentree/venv/bin/activate

cd /home/opentree/statistics

python phylesystem_stats.py -f devstats/phylesystem.json -s devapi.opentreeoflife.org

rsync -e "ssh -i $HOME/.ssh/id_statistics_push" -ptv $HOME/statistics/devstats/phylesystem.json opentree@devtree.opentreeoflife.org:/statistics

