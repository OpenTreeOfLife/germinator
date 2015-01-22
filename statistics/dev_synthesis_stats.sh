#!/bin/sh

. /home/opentree/venv/bin/activate

cd /home/opentree/statistics

python synthesis_stats.py -f devstats/synthesis.json -s devapi.opentreeoflife.org

rsync -e "ssh -i $HOME/.ssh/id_statistics_push" -ptv $HOME/statistics/devstats/synthesis.json opentree@devtree.opentreeoflife.org:/statistics

