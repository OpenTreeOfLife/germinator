#!/bin/bash

CONTROLLER=$1 

OPENTREE_WEBAPI_BASE_URL=$2

# We expect the taxonomy to be in taxonomy.tgz, and
# the synthetic tree to be in synth.tre.gz (or synth.tgz).

# Method #1: from web, on server
# cd repo/reference-taxonomy/service
# wget -O taxonomy.tgz http://files.opentreeoflife.org/ott/ott2.9/ott2.9.tgz
# wget -O synth.tre.gz http://files.opentreeoflife.org/trees/draftversion4.tre.gz

# Method #2: from local files, on client
# cd repo/germinator/asterales
# scp -p subset.tgz asterales:repo/reference-taxonomy/service/
# scp -p subset.tre.gz asterales:repo/reference-taxonomy/service/

set -e
. setup/functions.sh

# Ensure local clone is up to date
if git_refresh OpenTreeOfLife reference-taxonomy; then

  # Recompile
  (cd repo/reference-taxonomy; make compile)

fi

(cd repo/reference-taxonomy; rm -f bin/smasher; make bin/smasher)

# Uncompress if necessary
function deal {
    which=$1                    # taxonomy or synth
    BACK=$PWD
    cd repo/reference-taxonomy/service
    # Get taxonomy or tree if not aready there
    if [ -d ${which} ]; then
        true
    elif [ -r ${which}.tre ]; then
        true
    elif [ -r ${which}.tgz ]; then
        mkdir ${which}.in
        echo "Uncompressing ${which}.tgz"
        (cd ${which}.in; tar xzf ../${which}.tgz)
        ln -sf ${which}.in/* ${which}
    elif [ -r ${which}.tre.gz ]; then
        echo "Uncompressing ${which}.tre.gz"
        gunzip ${which}.tre.gz
    else
        echo "** No gz file found for ${which}"
        ls -l
        exit 1
    fi
    cd $BACK
}

deal taxonomy
deal synth

# Cf. index-doc-store.sh
if [ ${OPENTREE_WEBAPI_BASE_URL:0:2} = '//' ]; then
    OPENTREE_WEBAPI_BASE_URL=https:$OPENTREE_WEBAPI_BASE_URL
fi

# Create config file
echo STUDY_BASE_URL="${OPENTREE_WEBAPI_BASE_URL}"/v3/study/ >repo/reference-taxonomy/service/service.config

# Stop the HTTP server, if running
repo/reference-taxonomy/bin/smasher stop || true

# Restart the HTTP server
echo Starting smasher
repo/reference-taxonomy/bin/smasher start

log "Started smasher"
