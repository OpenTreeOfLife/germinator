#!/bin/bash

# Some of this repeats what's found in install-web2py-apps.sh.  Keep in sync.

# Lots of arguments to make this work.. check to see if we have them all.
if [ "$#" -ne 13 ]; then
    echo "install-api.sh missing required parameters (expecting 13)"
    exit 1
fi

OPENTREE_HOST=$1
OPENTREE_DOCSTORE=$2
COLLECTIONS_REPO=$3
AMENDMENTS_REPO=$4
FAVORITES_REPO=$5
export CONTROLLER=$6
OTI_BASE_URL=$7
OPENTREE_API_BASE_URL=$8
COLLECTIONS_API_BASE_URL=$9
AMENDMENTS_API_BASE_URL=${10}
FAVORITES_API_BASE_URL=${11}
OPENTREE_DEFAULT_APPLICATION=${12}
OTINDEX_BASE_URL=${13}

. setup/functions.sh || exit 1


bash setup/install-web2py.sh || exit 1

echo "Installing API" || exit 1


#Pre installs for normal phylestem-api venv
venv/bin/pip  install vine==1.3 || exit 1
#Force early version of vine in venv to deal with python2 python3 issues
venv/bin/pip install kombu==4.1.0 || exit 1
venv/bin/pip install celery==4.1.0 || exit 1




# ---------- Redis for caching ---------
#This is in the default venv
REDIS_WITH_VERSION="redis-3.0.0"
if ! test -f redis/bin/redis-server ; then
    if ! test -d "downloads/${REDIS_WITH_VERSION}" ; then
        if ! test -f downloads/"${REDIS_WITH_VERSION}.tar.gz" ; then
            wget --no-verbose -O downloads/"${REDIS_WITH_VERSION}.tar.gz" http://download.redis.io/releases/"${REDIS_WITH_VERSION}".tar.gz
        fi
        (cd downloads; \
            tar xfz "${REDIS_WITH_VERSION}.tar.gz")
    fi
    if ! test -d redis/work ; then
        mkdir -p redis/work || exit 1
        (cd downloads/${REDIS_WITH_VERSION} ; \
            make && make PREFIX="${HOME}/redis" install) || exit 1
    fi
fi



# ---------- API & TREE STORE ----------
# Set up api web app
# Compare install-web2py-apps.sh

WEBAPP=phylesystem-api
APPROOT=repo/$WEBAPP
OTHOME=$PWD

# This is required to make "git pull" work correctly
git config --global user.name "OpenTree API" || exit 1
git config --global user.email api@opentreeoflife.org || exit 1

echo "...fetching $WEBAPP repo..." || exit 1
git_refresh OpenTreeOfLife $WEBAPP || true

if [ "${PEYOTL_LOG_FILE_PATH:0:1}" != "/" ]; then
    PEYOTL_LOG_FILE_PATH="$OTHOME"/"$PEYOTL_LOG_FILE_PATH"
fi

git_refresh OpenTreeOfLife peyotl || true
py_package_setup_install peyotl || true

(cd $APPROOT; pip install -r requirements.txt) || exit 1
(cd $APPROOT/ot-celery; pip install -r requirements.txt ; python setup.py develop) || exit 1

(cd web2py/applications; \
    rm -rf ./phylesystem ; \
    ln -sf ../../repo/$WEBAPP ./phylesystem) || exit 1

# ---------- DOC STORE ----------

echo "...fetching $OPENTREE_DOCSTORE repo..."

phylesystem=repo/${OPENTREE_DOCSTORE}_par/$OPENTREE_DOCSTORE
mkdir -p repo/${OPENTREE_DOCSTORE}_par
git_refresh OpenTreeOfLife $OPENTREE_DOCSTORE "$BRANCH" repo/${OPENTREE_DOCSTORE}_par || true

pushd .
    cd $phylesystem
    # All the repos above are cloned via https, but we need to push via
    # ssh to use our deploy keys
    if ! grep "originssh" .git/config ; then
        git remote add originssh git@github.com:OpenTreeOfLife/$OPENTREE_DOCSTORE.git
    fi
popd

pushd .
    cd $APPROOT/private
    cp config.example config
    sed -i -e "s+PHYLESYSTEM_REPO_PATH+$OTHOME/repo/${OPENTREE_DOCSTORE}_par/$OPENTREE_DOCSTORE+" config
    sed -i -e "s+PHYLESYSTEM_REPO_PAR+$OTHOME/repo/${OPENTREE_DOCSTORE}_par+" config

    # Specify our remote to push to, which is added to local repo above
    sed -i -e "s+PHYLESYSTEM_REPO_REMOTE+originssh+" config

    # This wrapper script allows us to specify an ssh key to use in git pushes
    sed -i -e "s+GIT_SSH+$OTHOME/repo/$WEBAPP/bin/git.sh+" config

    # This is the file location of the SSH key that is used in git.sh
    sed -i -e "s+PKEY+$OTHOME/.ssh/opentree+" config

    # Access oti search from shared server-config variable
    sed -i -e "s+OTI_BASE_URL+$OTI_BASE_URL+" config

    # Access otindex search from shared server-config variable
    sed -i -e "s+OTINDEX_BASE_URL+$OTINDEX_BASE_URL+" config

    sed -i -e "s+COLLECTIONS_API_BASE_URL+$COLLECTIONS_API_BASE_URL+" config
    sed -i -e "s+AMENDMENTS_API_BASE_URL+$AMENDMENTS_API_BASE_URL+" config
    sed -i -e "s+FAVORITES_API_BASE_URL+$FAVORITES_API_BASE_URL+" config

    # Define the public URL of the docstore repo (used for updating oti)
    # N.B. Because of limitations oti's index_current_repo.py, this is
    # always one of our public repos on GitHub.
    sed -i -e "s+OPENTREE_DOCSTORE_URL+https://github.com/OpenTreeOfLife/$OPENTREE_DOCSTORE+" config

    #logging stuff
    sed -i -e "s+OPEN_TREE_API_LOGGING_LEVEL+${OPEN_TREE_API_LOGGING_LEVEL}+" config
    sed -i -e "s+OPEN_TREE_API_LOGGING_FORMATTER+${OPEN_TREE_API_LOGGING_FORMATTER}+" config
    if [ "${OPEN_TREE_API_LOGGING_FILEPATH:0:1}" != "/" ]; then
        OPEN_TREE_API_LOGGING_FILEPATH="$OTHOME"/"$OPEN_TREE_API_LOGGING_FILEPATH"
    fi
    sed -i -e "s+OPEN_TREE_API_LOGGING_FILEPATH+${OPEN_TREE_API_LOGGING_FILEPATH}+" config
popd

# N.B. Another file 'GITHUB_CLIENT_SECRET' was already placed via rsync (in push.sh)
# Also 'OPENTREEAPI_OAUTH_TOKEN'

# prompt to add a GitHub webhook (if it's not already there) to nudge my oti service as studies change
pushd .
    # TODO: Pass in credentials for bot user 'opentree' on GitHub, to use the GitHub API for this:
    cd $OTHOME/repo/$WEBAPP/bin
    tokenfile=~/.ssh/OPENTREEAPI_OAUTH_TOKEN
    if [ -r $tokenfile ]; then
        python add_or_update_webhooks.py https://github.com/OpenTreeOfLife/$OPENTREE_DOCSTORE https://github.com/OpenTreeOfLife/$AMENDMENTS_REPO $OPENTREE_API_BASE_URL $tokenfile
    else
        echo "OPENTREEAPI_OAUTH_TOKEN not found (install-api.sh), prompting for manual handling of webhooks."
        python add_or_update_webhooks.py https://github.com/OpenTreeOfLife/$OPENTREE_DOCSTORE https://github.com/OpenTreeOfLife/$AMENDMENTS_REPO $OPENTREE_API_BASE_URL
    fi
popd

# ---------- MINOR REPOS ----------
# Setup COLLECTIONS_REPO, FAVORITES_REPO, any others

echo "...fetching minor repos..."
echo "   ${COLLECTIONS_REPO}..."

collections=repo/${COLLECTIONS_REPO}_par/$COLLECTIONS_REPO
mkdir -p repo/${COLLECTIONS_REPO}_par
git_refresh OpenTreeOfLife $COLLECTIONS_REPO "$BRANCH" repo/${COLLECTIONS_REPO}_par || true

pushd .
    cd $collections
    # All the repos above are cloned via https, but we need to push via
    # ssh to use our deploy keys
    if ! grep "originssh" .git/config ; then
        git remote add originssh git@github.com:OpenTreeOfLife/$COLLECTIONS_REPO.git
    fi
popd

echo "   ${AMENDMENTS_REPO}..."

amendments=repo/${AMENDMENTS_REPO}_par/$AMENDMENTS_REPO
mkdir -p repo/${AMENDMENTS_REPO}_par
git_refresh OpenTreeOfLife $AMENDMENTS_REPO "$BRANCH" repo/${AMENDMENTS_REPO}_par || true

pushd .
    cd $amendments
    if ! grep "originssh" .git/config ; then
        git remote add originssh git@github.com:OpenTreeOfLife/$AMENDMENTS_REPO.git
    fi
popd

echo "   ${FAVORITES_REPO}..."

favorites=repo/${FAVORITES_REPO}_par/$FAVORITES_REPO
mkdir -p repo/${FAVORITES_REPO}_par
git_refresh OpenTreeOfLife $FAVORITES_REPO "$BRANCH" repo/${FAVORITES_REPO}_par || true

pushd .
    cd $favorites
    # All the repos above are cloned via https, but we need to push via
    # ssh to use our deploy keys
    if ! grep "originssh" .git/config ; then
        git remote add originssh git@github.com:OpenTreeOfLife/$FAVORITES_REPO.git
    fi
popd

# more modifications to existing app config
# TODO: add these placeholders to app config template!
pushd .
    cd $APPROOT/private
    sed -i -e "s+COLLECTIONS_REPO_PATH+$OTHOME/repo/${COLLECTIONS_REPO}_par/$COLLECTIONS_REPO+" config
    sed -i -e "s+COLLECTIONS_REPO_PAR+$OTHOME/repo/${COLLECTIONS_REPO}_par+" config
    sed -i -e "s+AMENDMENTS_REPO_PATH+$OTHOME/repo/${AMENDMENTS_REPO}_par/$AMENDMENTS_REPO+" config
    sed -i -e "s+AMENDMENTS_REPO_PAR+$OTHOME/repo/${AMENDMENTS_REPO}_par+" config
    sed -i -e "s+FAVORITES_REPO_PATH+$OTHOME/repo/${FAVORITES_REPO}_par/$FAVORITES_REPO+" config
    sed -i -e "s+FAVORITES_REPO_PAR+$OTHOME/repo/${FAVORITES_REPO}_par+" config

    # Specify our remotes to push to (added to local repos above)
    sed -i -e "s+COLLECTIONS_REPO_REMOTE+originssh+" config
    sed -i -e "s+AMENDMENTS_REPO_REMOTE+originssh+" config
    sed -i -e "s+FAVORITES_REPO_REMOTE+originssh+" config

    # N.B. Assume we're using the same ssh keys as for the main OPENTREE_DOCSTORE

    # Define the public URLs of the minor repos (used for updating oti)
    # N.B. Because of limitations oti's index_current_repo.py, this is
    # always one of our public repos on GitHub.
    sed -i -e "s+COLLECTIONS_REPO_URL+https://github.com/OpenTreeOfLife/$COLLECTIONS_REPO+" config
    sed -i -e "s+AMENDMENTS_REPO_URL+https://github.com/OpenTreeOfLife/$AMENDMENTS_REPO+" config
    sed -i -e "s+FAVORITES_REPO_URL+https://github.com/OpenTreeOfLife/$FAVORITES_REPO+" config
popd

# Add a simple parametric router to set our default web2py app
echo "PWD (install-api):"
echo "$(pwd)"
pushd .
    TMP=/tmp/tmp.tmp
    echo default_application should be "$OPENTREE_DEFAULT_APPLICATION" || exit 1
    sed -e "s+default_application='.*'+default_application='$OPENTREE_DEFAULT_APPLICATION'+" \
       web2py/examples/routes.parametric.example.py >$TMP || exit 1
    cp $TMP web2py/routes.py || exit 1
    rm $TMP || exit 1
    grep default_ web2py/routes.py || exit 1
popd

# ---------- REDIS AND CELERY ----------

echo "copy redis config and start redis"
# Make sure that redis has the up-to-date config from the api repo...
cp $APPROOT/private/ot-redis.config redis/ot-redis.config
# somewhat hacky shutdown and restart redis
echo 'shutdown' | redis/bin/redis-cli
nohup redis/bin/redis-server redis/ot-redis.config &

echo "restarting a celery worker"
celery multi restart worker -A open_tree_tasks -l info

echo "Apache needs to be restarted (API)"
