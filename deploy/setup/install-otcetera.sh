#!/bin/bash

# Name of user who ran the 'push.sh' command
CONTROLLER=$1 

# Exit immediately in a command has a non-zero exit status
set -e 
# Load config file and also some function definitions
. setup/functions.sh

# renice: don't slow down other processes
renice 10 $$

# Override default to use all cores, because parallel builds use more memory, and can fail on devapi.
# We should remove the override on machines that have enough RAM
alias ninja='ninja -j1'

# 1. Make the OpenTree directory
APPS=$HOME/Applications
mkdir -p $APPS

OPENTREE=$APPS/OpenTree
mkdir -p $OPENTREE

# 2. Install the taxonomy && define OTT
TAX_FILE=${TAX_URL##*/}
TAX_DIR=${TAX_FILE%.*}
OTT=$OPENTREE/$TAX_DIR

DARK_RED='\033[0;31m'
LIGHT_GREEN='\033[1;32m'
NC='\033[0m'
LIGHT_CYAN='\033[1;36m'
FAIL="[${DARK_RED}FAIL${NC}]"
OK="[${LIGHT_GREEN}OK${NC}]"

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
	
# FIXME: probably we should check out a stable branch, instead of master.
# But 5.0 isn't stable.
branch=master

# 4a. Build restbed: update source
if [ -d $APPS/restbed/restbed ] ; then
    (
        cd $APPS/restbed/restbed
        echo -e "${LIGHT_CYAN}Restbed: updating source: starting ...${NC}"
        git checkout "${branch}"
        git pull
        git submodule update
        echo -e "${LIGHT_CYAN}Restbed: updating source: ${LIGHT_GREEN}done.${NC}"
    )
else
    (
        echo -e "${LIGHT_CYAN}Restbed: cloning source: starting ...${NC}"
        mkdir -p $APPS/restbed
        cd $APPS/restbed
        git clone https://github.com/corvusoft/restbed.git
        git checkout "${branch}"
        git submodule update
        echo -e "${LIGHT_CYAN}Restbed: cloning source: ${LIGHT_GREEN}done.${NC}"
    )
fi

#4b. Build restbed: build.
mkdir -p $APPS/restbed/build
if ! (cd $APPS/restbed/build && cmake -DBUILD_SSL=NO -DCMAKE_INSTALL_PREFIX=$APPS/restbed/local/ ../restbed -G Ninja && ninja install) ; then
    echo "Blowing away pre-existing restbed build and trying from scratch..."
    rm -rf $APPS/restbed/build $APPS/restbed/local
    mkdir -p $APPS/restbed/build
    cd $APPS/restbed/build && cmake -DBUILD_SSL=NO -DCMAKE_INSTALL_PREFIX=$APPS/restbed/local/ ../restbed -G Ninja && ninja install
fi

if [ -r $APPS/restbed/local/include/restbed ] && [ -r $APPS/restbed/local/lib/librestbed.a ] ; then
    echo "restbed: installed."
else
    echo "** Failed to install restbed"
fi

# Make sure apps linked against these libraries know where to find them.
export LD_RUN_PATH=$APPS/restbed/local/lib/

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
    git branch --track deployed origin/deployed
    git checkout deployed
    )
fi

log Checkout: otcetera `git log | head -1`

(
    export LDFLAGS=-L${APPS}/restbed/local/lib
    export CPPFLAGS=-I${APPS}/restbed/local/include

    # We need to check a full build, since change to defaults aren't applied to pre-existing project dirs.
    if  ! (cd ./build && ninja install) ; then
	rm -r ../otcetera/build
	meson otcetera build --prefix=$APPS/otcetera/local
        (cd ./build && ninja install)
    fi
)
if [ -r "$SERVER" ] ; then
    echo "otc-tol-ws: installed."
else
    echo "** otc-tol-ws: not found!"
fi


# 6. Run the service
PIDFILE=$OPENTREE/wspidfile.txt
cd $OPENTREE

# FIXME: Ideally we only kill the server if we had to rebuild anything...

# FIXME: We need to check if killing the old server actually succeeds!
echo -n "Killing the old server process: "
killall -9 -q otc-tol-ws || true
sleep 1
if pgrep -x "otc-tol-ws" ; then
    echo -e "${FAIL}"
else
    echo -e "${OK}"
fi

echo -ne "${LIGHT_CYAN}Starting otcetera web services (otc-tol-ws)${NC}: "
LD_LIBRARY_PATH=${APPS}/restbed/local/lib /usr/sbin/daemonize -c $OPENTREE $SERVER $OTT -D$SYNTHPARENT -p$PIDFILE -P1984 --num-threads=4
sleep 1
if pgrep -x "otc-tol-ws" ; then
    echo -e "${OK}"
else
    echo -e "${FAIL}"
    tail $OPENTREE/logs/myeasylog.log || true
fi

# 7. Install the wrapper
cd
git_refresh OpenTreeOfLife ws_wrapper || true
py_package_setup_install ws_wrapper || true
WPIDFILE=$HOME/repo/ws_wrapper/pid
(pkill -F "$WPIDFILE" 2>/dev/null || true ) && /usr/sbin/daemonize -p $WPIDFILE -c $HOME/repo/ws_wrapper ${VIRTUAL_ENV}/bin/pserve development.ini
