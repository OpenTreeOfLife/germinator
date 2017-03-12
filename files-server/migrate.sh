#!/bin/sh

set -e

path=$1

# The following assumes you're on a Mac and have done
#   pip install --upgrade --user awscli

[ x$PYTHON_BIN = x ] && \
    PYTHON_BIN=~/Library/Python/2.7/bin

[ ! -e $path ] && (echo Cannot find $path; exit 1)

echo "Copying $path to s3://files.opentreeoflife.org/$path - no, dry run"

# $PYTHON_BIN/aws s3 cp $path s3://files.opentreeoflife.org/$path

