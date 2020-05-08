#!/bin/bash
set -x

# Name of user who ran the 'push.sh' command
CONTROLLER=$1 

if [ "$#" -ne 2 ]; then
    echo "install-octcetera.sh missing required parameters (expecting 2)"
    exit 1
fi

OPENTREE_WEBAPI_BASE_URL=$2
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

VIRTUAL_ENV_PYTHON3=${HOME}/venvp3

#Use python3 venvp3 for otcetera build
${VIRTUAL_ENV_PYTHON3}/bin/pip install meson

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
SYNTH_DIR=${SYNTH_FILE%.tgz}

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
restbedbranch=master

# 4a. Build restbed: update source
export CXX=$(which g++-8)
if [ -d $APPS/restbed/restbed ] ; then
    (
        cd $APPS/restbed/restbed
        echo -e "${LIGHT_CYAN}Restbed: updating source: starting ...${NC}"
        git checkout "${restbedbranch}"
        git pull
        echo -e "${LIGHT_CYAN}Restbed: updating source: ${LIGHT_GREEN}done.${NC}"
        git submodule init
        git submodule update
    )
else
    (
        echo -e "${LIGHT_CYAN}Restbed: cloning source: starting ...${NC}"
        mkdir -p $APPS/restbed
        cd $APPS/restbed
        git clone https://github.com/corvusoft/restbed.git
        cd $APPS/restbed/restbed
        git checkout "${restbedbranch}"
        echo -e "${LIGHT_CYAN}Restbed 4: cloning source: ${LIGHT_GREEN}done.${NC}"
        git submodule init
        git submodule update
    )
fi

#4b. Build restbed: build.
mkdir -p $APPS/restbed/build
if ! (cd $APPS/restbed/build && cmake -DBUILD_TESTS=NO -DBUILD_SSL=NO -DCMAKE_INSTALL_PREFIX=$APPS/restbed/local/ ../restbed -DCMAKE_POSITION_INDEPENDENT_CODE=ON -G Ninja && ninja install) ; then
    echo "Blowing away pre-existing restbed build and trying from scratch..."
    rm -rf $APPS/restbed/build $APPS/restbed/local
    mkdir -p $APPS/restbed/build
    cd $APPS/restbed/build && cmake -DBUILD_TESTS=NO -DBUILD_SSL=NO -DCMAKE_INSTALL_PREFIX=$APPS/restbed/local/ ../restbed -DCMAKE_POSITION_INDEPENDENT_CODE=ON -G Ninja && ninja install
fi

if [ -r $APPS/restbed/local/include/restbed ] && [ -r $APPS/restbed/local/library/librestbed.a ] ; then
    echo "restbed: installed."
else
    echo "** Failed to install restbed"
    exit 1
fi

# Make sure apps linked against these libraries know where to find them.
export LD_RUN_PATH=$APPS/restbed/local/library/

#5. Build otcetera with web services
SERVER=$APPS/otcetera/local/bin/otc-tol-ws

otceterabranch=${OPENTREE_BRANCHES[otcetera]}
        if [ x$branch = x ]; then
            branch='master'
        fi


mkdir -p $APPS/otcetera
cd $APPS/otcetera
if [ -d otcetera ] ; then
    (
    cd otcetera
    git fetch
    git checkout "${otceterabranch}"
    git pull
    )
else
    (
    git clone --recursive https://github.com/OpenTreeOfLife/otcetera
    cd otcetera
#    git branch --track ${otceterabranch} origin/${otceterabranch}
    git checkout "${otceterabranch}"
    )
fi

log Checkout: otcetera `git log | head -1`

(
    export LDFLAGS=-L${APPS}/restbed/local/library
    export CPPFLAGS=-I${APPS}/restbed/local/include
    export CXX=$(which g++-8)

    echo $PWD
    # We need to check a full build, since change to defaults aren't applied to pre-existing project dirs.
    if  ! (cd ./build && ninja install) ; then
    rm -rf ../otcetera/build
    ${VIRTUAL_ENV_PYTHON3}/bin/meson otcetera build --prefix=$APPS/otcetera/local
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
LD_LIBRARY_PATH=${APPS}/restbed/local/library /usr/sbin/daemonize -c $OPENTREE $SERVER $OTT -D$SYNTHPARENT -p$PIDFILE -P1984 --num-threads=4
sleep 1
if pgrep -x "otc-tol-ws" ; then
    echo -e "${OK}"
else
    echo -e "${FAIL}"
    tail $OPENTREE/logs/myeasylog.log || true
fi

# 7. Install the wrapper
cd
${VIRTUAL_ENV}/bin/pip install configparser



# Until ws_wrapper chang e is merged, need to select use template branch
#git_refresh OpenTreeOfLife ws_wrapper ini-template || true
git_refresh OpenTreeOfLife ws_wrapper || true

git_refresh OpenTreeOfLife peyotl || true

cd $HOME/repo/peyotl/
${VIRTUAL_ENV_PYTHON3}/bin/pip install -r requirements.txt
${VIRTUAL_ENV_PYTHON3}/bin/python setup.py develop


cd $HOME/repo/ws_wrapper/
${VIRTUAL_ENV_PYTHON3}/bin/python setup.py develop

WPIDFILE=$HOME/repo/ws_wrapper/pid

#make new ini from a template and .gitignore it
cp $HOME/repo/ws_wrapper/template.ini $HOME/repo/ws_wrapper/wswrapper.ini
sed -i -e "s+OPENTREE_WEBAPI_BASE_URL+${OPENTREE_WEBAPI_BASE_URL}+" $HOME/repo/ws_wrapper/wswrapper.ini

(pkill -F "$WPIDFILE" 2>/dev/null || true ) && /usr/sbin/daemonize -p $WPIDFILE -c $HOME/repo/ws_wrapper ${VIRTUAL_ENV_PYTHON3}/bin/pserve wswrapper.ini
