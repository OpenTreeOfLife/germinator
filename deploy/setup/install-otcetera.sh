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
OTT=$OPENTREE/$TAX_DIR

if [ ! -e "$OTT" ] ; then
    mkdir -p $OTT
    (
	cd $OPENTREE
	wget -O $TAX_FILE $TAX_URL
	(
	    cd $OTT
	    tar -zxf ../${TAX_FILE} --strip-components=1;
	)
    )
    if [ ! -e "$OTT/version.txt" ] ; then
	echo "** Failed to install taxonomy file $TAX_URL"
    fi
fi
echo "Taxonomy: installed."

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
echo "Synth tree: installed."
	
# 4. build restbed
if [ ! -r $APPS/restbed/local/include/restbed ] ; then
    if [ -d $APPS/restbed/restbed ] ; then
	echo "Restbed: using previously cloned source."
    else
	mkdir -p $APPS/restbed/build
	(
	    cd $APPS/restbed
	    git clone --recursive https://github.com/corvusoft/restbed.git
	)
    fi
    (
	cd $APPS/restbed/build
	cmake -DCMAKE_INSTALL_PREFIX=$APPS/restbed/local/ ../restbed
	make
	make install
    )
fi
echo "restbed: installed."
