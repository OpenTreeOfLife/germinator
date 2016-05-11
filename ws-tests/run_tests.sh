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

if [[ $baseurl =~ ^http: ]]; then
    echo "Base URL must start with https"
    exit 1
fi

args="host:apihost=$baseurl host:allowwrite=false"

for repo in phylesystem-api treemachine taxomachine oti reference-taxonomy ; do
    ./repo_tests.sh $repo $args
done
