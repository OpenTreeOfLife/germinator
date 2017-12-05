#!/bin/bash

# push.sh -c {configfile} {command} {arg...}  - see README.md for documentation
# The command is either a component to install, or an operation to
# perform.  Components are opentree [web app], api, taxomachine, etc.
# Operation to perform would be copying a neo4j database image or
# invoking the OTI indexing operation.

# If command is missing, components are pushed to the server according
# to OPENTREE_COMPONENTS as defined in the config file.

# You may wonder about my use of $foo vs. ${foo} vs. "$foo" vs. "${foo}".
# It's basically random.  I'm expecting to come up with some rules for
# choosing between these any day now.
# As far as I can tell, you use {} in case of concatenation with a
# letter or digit, and you use "" to protect against the possibility
# of there being a space in the variable value.

function err {
    echo "Error: $@" 1>&2
    exit 1
}

set -e

# $0 -h <hostname> -u <username> -i <identityfile> -n <hostname>

# This function can be used in config files

function opentree_branch {
    # Ignore on this end, in case the currently executing bash doesn't
    # have associative arrays.  See functions.sh for the 'real' definition.
    true
}

# Command line argument processing

# declare -A OPENTREE_BRANCHES  - doesn't work in bash 3.2.48
#  but associative arrays seem to work without the declaration in
#  3.2.48 and in 4.2.37, contrary to documentation on web

DRYRUN=no
FORCE_COMPILE=no

# The user that is controlling the whole deployment business.  This gets recorded in the log.
if [ x$CONTROLLER = x ]; then
    CONTROLLER=`whoami`
fi

# Process command line flags; load config file (-c)
while [ $# -gt 0 ]; do
    if [ ${1:0:1} != - ]; then
        break
    fi
    flag=$1
    shift
    if [ "x$flag" = "x-c" ]; then
        # Config file overrides default parameter settings
        CONFIGFILE=$1
        source "$CONFIGFILE"; shift
    elif [ "x$flag" = "x-f" ]; then
        #echo "Forcing recompile!"
        FORCE_COMPILE=yes;
    elif [ "$flag" = "--dry-run" ]; then
        #echo "Dry run only!"
        DRYRUN=yes;
    else
        err "Unrecognized flag: $flag"
    fi
done

[ "x$CONFIGFILE" != x ] || err "No configuration file given (need -c {filename})"

# Configurable parameters
[ "x$CERTIFICATE_FILE" != x ] || CERTIFICATE_FILE=/etc/ssl/certs/opentree/STAR_opentreeoflife_org.pem
[ "x$CERTIFICATE_KEY_FILE" != x ] || CERTIFICATE_KEY_FILE=/etc/ssl/private/opentreeoflife.org.key

# OPENTREE_HOST (the server being set up) must always be specified, e.g.
# OPENTREE_HOST=devapi.opentreeoflife.org
[ "x$OPENTREE_HOST" != x ] || err "OPENTREE_HOST not specified"

# On ubuntu, the admin user is called 'ubuntu'; on debian it's 'admin'
[ "x$OPENTREE_ADMIN" != x ] || OPENTREE_ADMIN=admin

# Unprivileged user that runs all the services
[ "x$OPENTREE_USER" != x ] || OPENTREE_USER=opentree

# OPENTREE_SECRETS is the *local* directory where .pem and other
# private files are kept
[ "x$OPENTREE_SECRETS" != x ] || OPENTREE_SECRETS=~/.ssh/opentree
[ -d ${OPENTREE_SECRETS} ] || err "Directory ${OPENTREE_SECRETS} not found"

# ssh private key for unprivileged
[ "x$OPENTREE_IDENTITY" != x ] || OPENTREE_IDENTITY=${OPENTREE_SECRETS}/opentree.pem

# ssh private key admin user (taking a shortcut here)
[ "x$ADMIN_IDENTITY" != x ] || ADMIN_IDENTITY=${OPENTREE_IDENTITY}

# for github
[ "x$OPENTREE_GH_IDENTITY" != x ] || OPENTREE_GH_IDENTITY=${OPENTREE_SECRETS}/opentree-gh.pem

# Which components to install on this server
[ "x$OPENTREE_COMPONENTS" != x ] || OPENTREE_COMPONENTS=most

# Which web2py application gets control of the site's home page
[ "x$OPENTREE_DEFAULT_APPLICATION" != x ] || OPENTREE_DEFAULT_APPLICATION=opentree

# Used by oauth
if [ "x$OPENTREE_PUBLIC_DOMAIN" = x ]; then
    echo "Defaulting OPENTREE_PUBLIC_DOMAIN to $OPENTREE_HOST"
    OPENTREE_PUBLIC_DOMAIN=$OPENTREE_HOST
fi
# WEBAPP_BASE_URL is only needed for defaulting other things
if [ "x$WEBAPP_BASE_URL" = x ]; then
    WEBAPP_BASE_URL=https://$OPENTREE_PUBLIC_DOMAIN
fi
[ "x$CURATION_GITHUB_CLIENT_ID" != x ] || CURATION_GITHUB_CLIENT_ID=ID_NOT_PROVIDED
[ "x$CURATION_GITHUB_REDIRECT_URI" != x ] || CURATION_GITHUB_REDIRECT_URI=$WEBAPP_BASE_URL/webapp/user/login
[ "x$TREEVIEW_GITHUB_CLIENT_ID" != x ] || TREEVIEW_GITHUB_CLIENT_ID=ID_NOT_PROVIDED
[ "x$TREEVIEW_GITHUB_REDIRECT_URI" != x ] || TREEVIEW_GITHUB_REDIRECT_URI=$WEBAPP_BASE_URL/curator/user/login

# WEBAPI_BASE_URL is only needed for defaulting other things
# The part of an API URL before the 'v2' (bare host URL).  Used by webapps
if [ "x$OPENTREE_WEBAPI_BASE_URL" = x ]; then
    OPENTREE_WEBAPI_BASE_URL=$WEBAPP_BASE_URL
fi

# "API" in the following is short for "Phylesystem API"
[ "x$OPENTREE_API_BASE_URL" != x ] || OPENTREE_API_BASE_URL=$OPENTREE_WEBAPI_BASE_URL
[ "x$COLLECTIONS_API_BASE_URL" != x ] || COLLECTIONS_API_BASE_URL=$OPENTREE_WEBAPI_BASE_URL
[ "x$AMENDMENTS_API_BASE_URL" != x ] || AMENDMENTS_API_BASE_URL=$OPENTREE_WEBAPI_BASE_URL
[ "x$FAVORITES_API_BASE_URL" != x ] || FAVORITES_API_BASE_URL=$OPENTREE_WEBAPI_BASE_URL
[ "x$CONFLICT_API_BASE_URL" != x ] || CONFLICT_API_BASE_URL=$OPENTREE_WEBAPI_BASE_URL

# End of configuration processing.

# Local abbreviation... no good reason for this, just makes commands shorter
ADMIN=$OPENTREE_ADMIN

# Local abbreviation
SSH="ssh -i ${OPENTREE_IDENTITY}"
ASSH="ssh -i ${ADMIN_IDENTITY}"

# For unprivileged actions to server
OT_USER=$OPENTREE_USER

echo "host=$OPENTREE_HOST, admin=$OPENTREE_ADMIN, pem=$OPENTREE_IDENTITY, controller=$CONTROLLER"

restart_apache=no

function process_arguments {
    sync_system
    docommand $*
    if [ $restart_apache = "yes" ]; then
        restart_apache
    fi
}

function docommand {

    if [ $# -eq 0 ]; then
        if [ $DRYRUN = yes ]; then echo "[no component or command]"; fi
        echo "No command. Deploying these components: $OPENTREE_COMPONENTS"
        for component in $OPENTREE_COMPONENTS; do
            docomponent $component
        done
        return
    fi

    command="$1"
    shift
    case $command in
    # Commands
    push-db | pushdb)
        push_neo4j_db $*
            ;;
    install-db)
        if [ $# = 2 ]; then
            install_neo4j_db $*
            # restart apache to clear the RAM cache (stale results)
            restart_apache=yes
        else
            err "Wrong number of arguments to install-db" $*
        fi
        ;;
    index  | indexoti | index-db)
        index_doc_store
            ;;
    apache)
        restart_apache=yes
            ;;
    echo)
        # Test ability to do remote commands inline...
        ${SSH} "$OT_USER@$OPENTREE_HOST" bash <<EOF
             echo $*
EOF
        ;;
    none)
        echo "No components specified.  Try configuring OPENTREE_COMPONENTS"
        ;;

    *)
        if ! in_list $command $OPENTREE_COMPONENTS; then
	    err "Unrecognized command, or component not in OPENTREE_COMPONENTS: $command"
	fi
        # Default if not a recognized command: treat as component name
        docomponent $command
    esac
}

# Push a single component

function docomponent {
    component=$1
    case $component in
    opentree)
        push_webapps
        restart_apache=yes
        ;;
    phylesystem-api | api)
        # 'api' option is for backward compatibility
        push_phylesystem_api
        restart_apache=yes
        ;;
    oti)
        push_neo4j oti
        ;;
    treemachine)
        push_neo4j treemachine
        # restart apache to clear the RAM cache (stale results)
        restart_apache=yes
        ;;
    taxomachine)
        push_neo4j taxomachine
        # restart apache to clear the RAM cache (stale results)
        restart_apache=yes
        ;;
    smasher)
        push_smasher
        ;;
    otcetera)
	push_otcetera
	;;
    *)
        echo "Unrecognized component: $component"
        ;;
    esac
}

# list="w x y"; in_list x $list; echo $?
# kjetil v halvorsen via stackoverflow - thank you
function in_list() {
       local search="$1"
       shift
       local list=("$@")
       for file in "${list[@]}" ; do
           [[ "$file" == "$search" ]] && return 0
       done
       return 1
    }

# Common setup utilities

function sync_system {
    echo "Syncing"
    if [ $DRYRUN = "yes" ]; then echo "[sync]"; return; fi
    # Do privileged stuff
    # Don't use rsync - might not be installed yet
    scp -p -i "${ADMIN_IDENTITY}" as-admin.sh "$OPENTREE_ADMIN@$OPENTREE_HOST":
    ${ASSH} "$ADMIN@$OPENTREE_HOST" ./as-admin.sh "$OPENTREE_HOST" "$OPENTREE_USER" \
       "$CERTIFICATE_FILE" "$CERTIFICATE_KEY_FILE"
    # Copy files over
    rsync -pr -e "${SSH}" "--exclude=*~" "--exclude=#*" setup "$OT_USER@$OPENTREE_HOST":
    # Bleh
    rsync -p -e "${SSH}" $CONFIGFILE "$OT_USER@$OPENTREE_HOST":setup/CONFIG
    }

# The install scripts modify the apache config files, so do this last
function restart_apache {
    if [ $DRYRUN = "yes" ]; then echo "[restarting apache]"; return; fi
    scp -p -i "${ADMIN_IDENTITY}" restart-apache.sh "$ADMIN@$OPENTREE_HOST":
    ${ASSH} "$ADMIN@$OPENTREE_HOST" bash restart-apache.sh "$OT_USER" "$OPENTREE_HOST" \
      "$CERTIFICATE_FILE" "$CERTIFICATE_KEY_FILE"
}

# Commands

function push_neo4j_db {
    if [ $DRYRUN = "yes" ]; then echo "[push_neo4j_db]"; return; fi
    # E.g. ./push.sh push-db localnewdb.db.tgz taxomachine
    TARBALL=$1
    APP=$2
    if [ x$APP = x -o x$TARBALL = x ]; then
        err "Usage: $0 -c {configfile} push-db {tarball} {application}"
    fi
    HEREBALL=downloads/$APP.db.tgz
    time rsync -vax -e "${SSH}" $TARBALL "$OT_USER@$OPENTREE_HOST":$HEREBALL
    install_neo4j_db $HEREBALL $APP
}

function install_neo4j_db {
    HEREBALL=$1
    APP=$2
    ${SSH} "$OT_USER@$OPENTREE_HOST" ./setup/install-db.sh $HEREBALL $APP $CONTROLLER
}

function index_doc_store {
    if [ $DRYRUN = "yes" ]; then echo "[index_doc_store]"; return; fi
    ${SSH} "$OT_USER@$OPENTREE_HOST" ./setup/index-doc-store.sh $OPENTREE_API_BASE_URL $CONTROLLER
}

# Component installation

function push_webapps {

    if [ $CURATION_GITHUB_CLIENT_ID = ID_NOT_PROVIDED ]; then echo "WARNING: Missing GitHub client ID! Curation UI will be disabled."; fi
    if [ $TREEVIEW_GITHUB_CLIENT_ID = ID_NOT_PROVIDED ]; then echo "WARNING: Missing GitHub client ID! Tree-view feedback will be disabled."; fi
    # We could default these (used by webapps), but for some reason we don't
    [ "x$TREEMACHINE_BASE_URL" != x ] || err "TREEMACHINE_BASE_URL not configured"
    [ "x$TAXOMACHINE_BASE_URL" != x ] || err "TAXOMACHINE_BASE_URL not configured"
    [ "x$OTI_BASE_URL"         != x ] || err "OTI_BASE_URL not configured"
    [ "x$CONFLICT_BASE_URL"    != x ] || err "CONFLICT_BASE_URL not configured"

    if [ $DRYRUN = "yes" ]; then echo "[opentree]"; return; fi
    ${SSH} "$OT_USER@$OPENTREE_HOST" ./setup/install-web2py-apps.sh "$OPENTREE_HOST" "${OPENTREE_PUBLIC_DOMAIN}" "${OPENTREE_DEFAULT_APPLICATION}" "$CONTROLLER" "${CURATION_GITHUB_CLIENT_ID}" "${CURATION_GITHUB_REDIRECT_URI}" "${TREEVIEW_GITHUB_CLIENT_ID}" "${TREEVIEW_GITHUB_REDIRECT_URI}" "${TREEMACHINE_BASE_URL}" "${TAXOMACHINE_BASE_URL}" "${OTI_BASE_URL}" "${OPENTREE_API_BASE_URL}" "${COLLECTIONS_API_BASE_URL}" "${AMENDMENTS_API_BASE_URL}" "${FAVORITES_API_BASE_URL}" "${CONFLICT_API_BASE_URL}"
    # place the files with secret GitHub API keys for curator and webapp (tree browser feedback) apps
    # N.B. This includes the final domain name, since we'll need different keys for dev.opentreeoflife.org, www.opentreeoflife.org, etc.
    keyfile=${OPENTREE_SECRETS}/treeview-GITHUB_CLIENT_SECRET-$OPENTREE_PUBLIC_DOMAIN
    if [ -r $keyfile ]; then
        rsync -pr -e "${SSH}" $keyfile "$OT_USER@$OPENTREE_HOST":repo/opentree/webapp/private/GITHUB_CLIENT_SECRET
    else
        echo "** Cannot find GITHUB_CLIENT_SECRET file $keyfile"
    fi
    keyfile=${OPENTREE_SECRETS}/curation-GITHUB_CLIENT_SECRET-$OPENTREE_PUBLIC_DOMAIN
    if [ -r $keyfile ]; then
        rsync -pr -e "${SSH}" $keyfile "$OT_USER@$OPENTREE_HOST":repo/opentree/curator/private/GITHUB_CLIENT_SECRET
    else
        echo "** Cannot find GITHUB_CLIENT_SECRET file $keyfile"
    fi

    # we’re using the bot for “anonymous” comments in the synth-tree explorer
    push_bot_identity
}

# Utility for all the webapps.
# See "getting a github oauth token" in the phylesystem-api documentation.

function push_bot_identity {
    # place an OAuth token for GitHub API by bot user 'opentreeapi'
    tokenfile=${OPENTREE_SECRETS}/OPENTREEAPI_OAUTH_TOKEN
    if [ -r $tokenfile ]; then
        rsync -pr -e "${SSH}" $tokenfile "$OT_USER@$OPENTREE_HOST":.ssh/OPENTREEAPI_OAUTH_TOKEN
        ${SSH} "$OT_USER@$OPENTREE_HOST" chmod 600 .ssh/OPENTREEAPI_OAUTH_TOKEN
    else
        echo "** Cannot find OPENTREEAPI_OAUTH_TOKEN file $tokenfile"
    fi
}

# Set up server's clone of phylesystem repo, and the web API
function push_phylesystem_api {
    if [ $DRYRUN = "yes" ]; then echo "[phylesystem-api]"; return; fi

    echo "Doc store is $OPENTREE_DOCSTORE"
    [ "x$OPENTREE_DOCSTORE" != "x" ] || err "OPENTREE_DOCSTORE not configured"
    [ "x$COLLECTIONS_REPO"  != "x" ] || err "COLLECTIONS_REPO not configured"
    [ "x$AMENDMENTS_REPO"   != "x" ] || err "AMENDMENTS_REPO not configured"
    [ "x$FAVORITES_REPO"    != "x" ] || err "FAVORITES_REPO not configured"
    [ "x$OTI_BASE_URL"      != "x" ] || err "OTI_BASE_URL not configured"
    [ "x$OTINDEX_BASE_URL"      != "x" ] || err "OTINDEX_BASE_URL not configured"

    push_bot_identity

    # Place private key for GitHub access
    if [ "x$OPENTREE_GH_IDENTITY" = "x" ]; then
        echo "Warning: OPENTREE_GH_IDENTITY not specified"
    elif [ ! -r $OPENTREE_GH_IDENTITY ]; then
        echo "Warning: $OPENTREE_GH_IDENTITY not found"
    else
        rsync -p -e "${SSH}" "$OPENTREE_GH_IDENTITY" "$OT_USER@$OPENTREE_HOST":.ssh/opentree
        ${SSH} "$OT_USER@$OPENTREE_HOST" chmod 600 .ssh/opentree
    fi

    # Try to place an OAuth token for GitHub API by bot user 'opentreeapi'
    tokenfile=${OPENTREE_SECRETS}/OPENTREEAPI_OAUTH_TOKEN
    if [ -r $tokenfile ]; then
        rsync -p -e "${SSH}" $tokenfile "$OT_USER@$OPENTREE_HOST":.ssh/OPENTREEAPI_OAUTH_TOKEN
        ${SSH} "$OT_USER@$OPENTREE_HOST" chmod 600 .ssh/OPENTREEAPI_OAUTH_TOKEN
    else
        echo "****************************\n  OAuth token file (${tokenfile}) not found!\n  Falling back to any existing token on the server, OR a prompt for manual creation of webhooks.\n****************************"
    fi

    ${SSH} "$OT_USER@$OPENTREE_HOST" ./setup/install-api.sh "$OPENTREE_HOST" \
           $OPENTREE_DOCSTORE $COLLECTIONS_REPO $AMENDMENTS_REPO $FAVORITES_REPO $CONTROLLER $OTI_BASE_URL $OPENTREE_API_BASE_URL $COLLECTIONS_API_BASE_URL $AMENDMENTS_API_BASE_URL $FAVORITES_API_BASE_URL $OPENTREE_DEFAULT_APPLICATION $OTINDEX_BASE_URL 
}

function push_neo4j {
    APP=$1
    if [ $DRYRUN = "yes" ]; then echo "[neo4j app: $APP]"; return; fi
    ${SSH} "$OT_USER@$OPENTREE_HOST" ./setup/install-neo4j-app.sh $CONTROLLER $APP $FORCE_COMPILE
}

function push_smasher {
    if [ $DRYRUN = "yes" ]; then echo "[push_smasher]"; return; fi
    echo push_smasher: ${OPENTREE_WEBAPI_BASE_URL}
    ${SSH} "$OT_USER@$OPENTREE_HOST" ./setup/install-smasher.sh ${CONTROLLER} ${OPENTREE_WEBAPI_BASE_URL}
}

function push_otcetera {
    if [ $DRYRUN = "yes" ]; then echo "[push_otcetera]"; return; fi
    echo push_otcetera:
    ${SSH} "$OT_USER@$OPENTREE_HOST" ./setup/install-otcetera.sh ${CONTROLLER}
}

process_arguments $*
