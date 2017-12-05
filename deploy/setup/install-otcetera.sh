#!/bin/bash

# Name of user who ran the 'push.sh' command
CONTROLLER=$1 

# Exit immediately in a command has a non-zero exit status
set -e 
# Load config file and also some function definitions
. setup/functions.sh

# 1. Make the OpenTree directory
APPS=$HOME/Applications
mkdir -p $APPS

OPENTREE=$APPS/OpenTree
mkdir -p $OPENTREE

# 2. Install the taxonomy && define OTT
TAX_FILE=${TAX_URL##*/}
TAX_DIR=${TAX_FILE%.*}
TAX_NEW_DIR=$(echo $TAX_DIR | sed "s/ott/ott-/")
OTT=$OPENTREE/$TAX_NEW_DIR

if [ ! -e "$OTT" ] ; then
    (
	cd $OPENTREE
	wget $TAX_URL
	tar -zxf ${TAX_FILE};
	ln -s $TAX_DIR $TAX_NEW_DIR
    )
    if [ ! -e "$OTT" ] ; then
	echo "** Failed to install taxonomy file $TAX_URL"
    fi
fi

# 3. Install the synth tree && define SYNTHPARENT
SYNTHPARENT=$OPENTREE/synth-par
mkdir -p $SYNTHPARENT
SYNTH_FILE=${SYNTH_URL##*/}
SYNTH_DIR=${SYNTH_FILE%_output.tgz}

if [ ! -d "$SYNTHPARENT/$SYNTH_DIR" ] ; then
    (
	cd $SYNTHPARENT
	wget $SYNTH_URL
	tar -zxf $SYNTH_FILE
    )
    if [ ! -d "$SYNTHPARENT/$SYNTH_DIR" ] ; then
	echo "** Failed to install synth tree $SYNTH_URL"
    fi
fi
	
# 4a. restbed: source
(
    cd $APPS
    mkdir -p restbed/build
    cd restbed
    git clone --recursive https://github.com/corvusoft/restbed.git
)

# 4b. restbed: build
(
    cd $APPS/restbed/build
    cmake -DCMAKE_INSTALL_PREFIX=$APPS/restbed/local/ ../restbed
    make
    make install
)
