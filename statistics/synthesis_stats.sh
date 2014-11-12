#!/bin/sh

. /home/opentree/venv/bin/activate

cd /home/opentree/statistics

python synthesis_stats.py -f synthesis.json -s devapi.opentreeoflife.org

scp synthesis.json devtree.opentreeoflife.org:/home/opentree/repo/opentree/webapp/static/stats/synthesis.json
