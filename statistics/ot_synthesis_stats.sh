#!/bin/sh

. /home/opentree/venv/bin/activate

cd /home/opentree/statistics

python synthesis_stats.py -f otstats/synthesis.json -s api.opentreeoflife.org

rsync -e "ssh -i $HOME/.ssh/id_statistics_push" -ptv $HOME/statistics/otstats/synthesis.json opentree@tree.opentreeoflife.org:/statistics

