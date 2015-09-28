#!/bin/bash

apihost=$1
if [ x$apihost = x ]; then
    echo "No api host specified"
    exit 1
fi

REPOS=`cd ../..; pwd`
PHYLESYSTEM_API_HOME=$REPOS/phylesystem-api
PYTHONPATH=PHYLESYSTEM_API_HOME:$PYTHONPATH

# The python test scripts all use the opentreetesting.py library

for repo in phylesystem-api treemachine taxomachine oti ; do
    testdir=$REPOS/$repo/ws-tests
    echo $testdir
    if [ -d $testdir ]; then
        cd $testdir
        $PHYLESYSTEM_API_HOME/ws-tests/run_tests.sh \
           host:apihost=http://$apihost \
           host:allowwrite=false
    fi
done
