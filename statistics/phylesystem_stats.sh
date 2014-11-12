#!/bin/sh

. /home/opentree/venv/bin/activate

cd /home/opentree/statistics

python phylesystem_stats.py -f phylesystem.json -s devapi.opentreeoflife.org

scp phylesystem.json devtree.opentreeoflife.org:/home/opentree/repo/opentree/webapp/static/stats/phylesystem.json
