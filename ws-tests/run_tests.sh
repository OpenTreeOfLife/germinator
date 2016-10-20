#!/bin/bash

# ./run_tests.sh [ -t {directory} ] section:param=value ...
# ./run_tests.sh [ -t {directory} ] URL

# See documentation in TESTING.md in this repository.

# URL = base URL of api server to be tested, e.g. https://api.opentreeoflife.org
#  converted to config setting host:apihost=URL

# Run this script on any computer.  germinator repo must be findable from . .
# Assumes repository clones are siblings of one another.

# Find directory containing opentreetesting.py

if [ -e ../germinator/ws-tests/opentreetesting.py ]; then
    gdir=../germinator/ws-tests
elif [ -e ../../germinator/ws-tests/opentreetesting.py ]; then
    gdir=../../germinator/ws-tests
elif [ -e opentreetesting.py ]; then
    gdir=.
elif [ -e ws-tests/opentreetesting.py ]; then
    gdir=ws-tests
else
    echo "Cannot find opentreetesting.py"
    exit 1
fi

# Find directory containing tests

if [ "x$1" = x-t ]; then
    tdir="$2"
    shift
    shift
    if [ -d "$tdir" ] && (ls "$tdir" | grep -q "^test_.*\\.py") ; then
        true
    elif [ -d "$tdir"/ws-tests ] && (ls "$tdir"/ws-tests | grep -q "^test_.*\\.py"); then
        tdir="$tdir"/ws-tests
    else
        echo "Cannot find test-containing directory $tdir"
        exit 1
    fi
elif (ls | grep -q "^test_.*\\.py") ; then
    tdir=.
elif [ -d ws-tests ] && (ls ws-tests | grep -q "^test_.*\\.py") ; then
    tdir=ws-tests
else
    echo "No tests directory specified, will run all tests"
    tdir=
fi

# Normalize the config parameters

if [ $# -lt 1 ]; then
    echo "No apihost specified"
    exit 1
fi

first_config_spec=$1
shift

if [[ ! "$first_config_spec" =~ "=" ]]; then
    if [[ "$first_config_spec" =~ ^http: ]]; then
        echo "Warning: you probably mean to say https:, not http:"
    fi
    first_config_spec=host:apihost=$first_config_spec
fi


config_specs="$first_config_spec $*"
if [[ ! "$config_specs" =~ "host:allowwrite=" ]]; then
    config_specs="$first_config_spec $* host:allowwrite=false"
fi


# The python test scripts all use the opentreetesting.py library,
# so its location has to be on PYTHONPATH.

function do_tests {
    tdir=$1

    if [[ $tdir =~ phylesystem-api ]] && ! python -c 'import peyotl' 2>/dev/null; then
        echo 'peyotl must be installed to run all phylesystem-api tests'
    fi

    gabs=`cd $gdir; pwd`
    num_tried=0
    num_passed=0
    num_failed=0
    num_skipped=0
    failed=''
    for fn in `cd $tdir; ls test_*.py`; do
        if (cd $tdir; PYTHONPATH=$gabs:$PYTHONPATH python "$fn" $config_specs > ".out_${fn}.txt"); then
            num_passed=$(expr 1 + $num_passed)
            /bin/echo -n "."
        elif [ $? = 3 ]; then
            # Exit status of 3 signals that the test was skipped.
            num_skipped=$(expr 1 + $num_skipped)
            /bin/echo -n "s"
        else
            num_failed=$(expr 1 + $num_failed)
            /bin/echo -n "F"
            failed="$failed $fn"
        fi
        num_tried=$(expr 1 + $num_tried)
    done
    echo
    echo "Passed $num_passed out of $num_tried tests."
    if [ $num_skipped -gt 0 ]; then
        echo "An 's' means a test was skipped." 
        echo "Skipped $num_skipped tests."
    fi
    if [ $num_failed -gt 0 ]; then
        echo "Failures: $failed"
        return 1
    fi
    return 0
}

if [ "x$tdir" != x ]; then
    do_tests "$tdir"
else
    for repo in phylesystem-api treemachine taxomachine oti reference-taxonomy ; do
        tdir=$gdir/../../$repo/ws-tests
        echo Running tests in $tdir
        do_tests $tdir
    done
fi
