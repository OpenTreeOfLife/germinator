#!/bin/bash

# See documentation in TESTING.md in this repository.

# Argument: base URL of api server to be tested, e.g. https://api.opentreeoflife.org
# Run this script on any computer.
# Assumes repository clones are siblings of one another.

baseurl=$1
if [ x$baseurl = x ]; then
    echo "No base URL (host) specified"
    exit 1
fi

REPOS=`cd ../..; pwd`
PHYLESYSTEM_API_HOME=$REPOS/phylesystem-api

# The python test scripts all use the opentreetesting.py library,
# so its location has to be on PYTHONPATH.

export PYTHONPATH=PHYLESYSTEM_API_HOME/ws-tests:$PYTHONPATH

# The following runs the run_tests.sh script in each repository.

for repo in phylesystem-api treemachine taxomachine oti ; do
    testdir=$REPOS/$repo/ws-tests
    if [ -d $testdir ]; then
        echo Running tests in $testdir
        cd $testdir
        $PHYLESYSTEM_API_HOME/ws-tests/run_tests.sh \
           host:apihost=$baseurl \
           host:allowwrite=false
    fi
done
