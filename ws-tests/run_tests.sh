#!/bin/bash

# See documentation in TESTING.md in this repository.

# Argument: DNS hostname of api server to be tested.
# Run this script on any computer.
# Assumes repository clones are siblings of one another.

apihost=$1
if [ x$apihost = x ]; then
    echo "No api host specified"
    exit 1
fi

REPOS=`cd ../..; pwd`
PHYLESYSTEM_API_HOME=$REPOS/phylesystem-api

# The python test scripts all use the opentreetesting.py library,
# so its location has to be on PYTHONPATH.

export PYTHONPATH=PHYLESYSTEM_API_HOME:$PYTHONPATH

# The following runs the run_tests.sh script in each repository.

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
