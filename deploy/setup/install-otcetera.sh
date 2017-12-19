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
fi

if [ -e "$OTT/version.txt" ] ; then
    echo "Taxonomy: installed."
else
    echo "** Failed to install taxonomy file $TAX_URL"
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
fi
if [ -d "$SYNTHPARENT/$SYNTH_DIR" ] ; then
    echo "Synth tree: installed."
else
    echo "** Failed to install synth tree $SYNTH_URL"
fi
	
# 4. Build restbed
if [ ! -r $APPS/restbed/local/include/restbed ] ; then
    mkdir -p $APPS/restbed
    if [ -d $APPS/restbed/restbed ] ; then
	echo "Restbed: using previously cloned source."
    else
	(
	    cd $APPS/restbed
	    git clone --recursive https://github.com/corvusoft/restbed.git
	)
    fi
    mkdir -p $APPS/restbed/build
    (
	cd $APPS/restbed/build
	cmake -DCMAKE_INSTALL_PREFIX=$APPS/restbed/local/ ../restbed
	make
	make install
    )
fi
if [ -r $APPS/restbed/local/include/restbed ] ; then
    echo "restbed: installed."
else
    echo "** Failed to install restbed"
fi

# Make sure apps linked against these libraries know where to find them.
export LD_RUN_PATH=$APPS/restbed/local/library/

#5. Build otcetera with web services
SERVER=$APPS/otcetera/local/bin/otc-tol-ws

mkdir -p $APPS/otcetera
cd $APPS/otcetera
if [ -d otcetera ] ; then
    (
	cd otcetera
	git pull
    )
else
    (
	git clone --recursive https://github.com/mtholder/otcetera
	cd otcetera
	./bootstrap.sh
    )
fi
mkdir -p build
(
    cd build
    export LDFLAGS=-L${APPS}/restbed/local/library
    export CPPFLAGS=-I${APPS}/restbed/local/include
    export CXXFLAGS="-Wno-unknown-pragmas"
    if [ ! -r Makefile ] ; then
	../otcetera/configure --prefix=$APPS/otcetera/local --with-webservices=yes
    fi
    make
    make install
)
if [ -r "$SERVER" ] ; then
    echo "otc-tol-ws: installed."
else
    echo "** otc-tol-ws: not found!"
fi


# 6. Run the service
PIDFILE=$OPENTREE/wspidfile.txt
cd $OPENTREE

# Ideally we only kill the server if we had to rebuild anything...
killall -q otc-tol-ws || true

/usr/sbin/daemonize -c $OPENTREE $SERVER $OTT -D$SYNTHPARENT -p$PIDFILE -P1984 --num-threads=4 --prefix=v3

# 7. Install the wrapper
cd
git_refresh OpenTreeOfLife ws_wrapper || true
py_package_setup_install ws_wrapper || true
WPIDFILE=$HOME/repo/ws_wrapper/pid
(pkill -F "$WPIDFILE" || true ) && /usr/sbin/daemonize -p $WPIDFILE -c $HOME/repo/ws_wrapper ${VIRTUAL_ENV}/bin/pserve production.ini
