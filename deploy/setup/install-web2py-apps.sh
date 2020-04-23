#!/bin/bash

# Some of this repeats what's found in install-api.sh.  Keep in sync.

# Lots of arguments to make this work.. check to see if we have them all.
if [ "$#" -ne 16 ]; then
    echo "install-web2py-apps.sh missing required parameters (expecting 16)"
    exit 1
fi

OPENTREE_HOST=$1  #Not used; set in functions.sh anyhow
OPENTREE_PUBLIC_DOMAIN=$2
OPENTREE_DEFAULT_APPLICATION=$3
CONTROLLER=$4
CURATION_GITHUB_CLIENT_ID=$5
CURATION_GITHUB_REDIRECT_URI=$6
TREEVIEW_GITHUB_CLIENT_ID=$7
TREEVIEW_GITHUB_REDIRECT_URI=$8
TREEMACHINE_BASE_URL=$9
# NOTE that args beyond nine must be referenced in curly braces
TAXOMACHINE_BASE_URL=${10}
OTI_BASE_URL=${11}
OPENTREE_API_BASE_URL=${12}
COLLECTIONS_API_BASE_URL=${13}
AMENDMENTS_API_BASE_URL=${14}
FAVORITES_API_BASE_URL=${15}
CONFLICT_BASE_URL=${16}

. setup/functions.sh



bash setup/install-web2py.sh || exit 1

echo "Installing web2py applications.  Hostname = $OPENTREE_HOST.  Public-facing domain = $OPENTREE_PUBLIC_DOMAIN"

# **** Begin setup that is common to opentree/curator and api

OTHOME=$PWD
if [ "${PEYOTL_LOG_FILE_PATH:0:1}" != "/" ]; then
    PEYOTL_LOG_FILE_PATH="$OTHOME"/"$PEYOTL_LOG_FILE_PATH"
fi

# the curator app's to_nexml import function
# requires peyotl (after Feb 20). This
# function may move to the API repo, but 
# until it does the curator app needs to
# install peyotl
git_refresh OpenTreeOfLife peyotl || true
py_package_setup_install peyotl || true

# ---------- BROWSER & CURATOR WEBAPPS ----------
# Set up web2py apps as directed in the README.md file
# Compare install-api.sh

WEBAPP=opentree
APPROOT=repo/$WEBAPP

# Make sure that we have the opentree Git repo before manipulating
# files inside of it below

git_refresh OpenTreeOfLife $WEBAPP || true

# ---------- WEB2PY CONFIGURATION ----------

# The web2py apps need to know their own host names, for
# authentication purposes.  'hostname' doesn't work on EC2 instances,
# so it has to be passed in as a parameter.

# N.B. Two other files with were already placed via rsync (in push.sh):
#   curator/private/GITHUB_CLIENT_SECRET
#   webapp/private/GITHUB_CLIENT_SECRET

# ---- main webapp (opentree)

configdir=repo/opentree/webapp/private
configtemplate=$configdir/config.example
configfile=$configdir/config

# Use the existence of a wildcard cert to trigger the use of HTTPS from within web2py.
if [ -r /etc/letsencrypt/live/opentreeoflife.org/fullchain.pem]; then
   SSL_CERTS_FOUND=true
else
   SSL_CERTS_FOUND=false
fi
echo "Triggering use of HTTPS from within web2py? [$SSL_CERTS_FOUND]" || exit 1

# Replace tokens in example config file to make the active config (assume this always changes)
cp -p $configtemplate $configfile || exit 1

# Append /cached to some API base URLs (for faster retrieval of common method calls)
# N.B. We now expect these base URLs to be simple domain names, with no trailing path!
#CACHED_TREEMACHINE_BASE_URL=$(sed "s+$+/cached+" <<< $TREEMACHINE_BASE_URL)
#CACHED_TAXOMACHINE_BASE_URL=$(sed "s+$+/cached+" <<< $TAXOMACHINE_BASE_URL)
#CACHED_OTI_BASE_URL=$(sed "s+$+/cached+" <<< $OTI_BASE_URL)
CACHED_TREEMACHINE_BASE_URL=$TREEMACHINE_BASE_URL
CACHED_TAXOMACHINE_BASE_URL=$TAXOMACHINE_BASE_URL
CACHED_OTI_BASE_URL=$OTI_BASE_URL

sed "s+github_client_id = .*+github_client_id = $TREEVIEW_GITHUB_CLIENT_ID+;
     s+github_redirect_uri = .*+github_redirect_uri = $TREEVIEW_GITHUB_REDIRECT_URI+
     s+hostdomain = .*+hostdomain = $OPENTREE_PUBLIC_DOMAIN+;
     s+treemachine = .*+treemachine = $TREEMACHINE_BASE_URL+
     s+taxomachine = .*+taxomachine = $TAXOMACHINE_BASE_URL+
     s+oti = .*+oti = $OTI_BASE_URL+
     s+opentree_api = .*+opentree_api = $OPENTREE_API_BASE_URL+
     s+collections_api_base_url = .*+collections_api_base_url = $COLLECTIONS_API_BASE_URL+
     s+amendments_api_base_url = .*+amendments_api_base_url = $AMENDMENTS_API_BASE_URL+
     s+favorites_api_base_url = .*+favorites_api_base_url = $FAVORITES_API_BASE_URL+
     s+conflict_api = .*+conflict_api = $CONFLICT_BASE_URL+
     s+CACHED_treemachine = .*+CACHED_treemachine = $CACHED_TREEMACHINE_BASE_URL+
     s+CACHED_taxomachine = .*+CACHED_taxomachine = $CACHED_TAXOMACHINE_BASE_URL+
     s+CACHED_oti = .*+CACHED_oti = $CACHED_OTI_BASE_URL+
     s+secure_sessions_with_HTTPS = .*+secure_sessions_with_HTTPS = $SSL_CERTS_FOUND+
    " < $configfile > tmp.tmp || exit 1
mv tmp.tmp $configfile || exit 1

# ---- curator webapp
configdir=repo/opentree/curator/private
configtemplate=$configdir/config.example
configfile=$configdir/config

# Replace tokens in example config file to make the active config (assume this always changes)
cp -p $configtemplate $configfile
sed "s+github_client_id = .*+github_client_id = $CURATION_GITHUB_CLIENT_ID+;
     s+github_redirect_uri = .*+github_redirect_uri = $CURATION_GITHUB_REDIRECT_URI+
     s+treemachine = .*+treemachine = $TREEMACHINE_BASE_URL+
     s+taxomachine = .*+taxomachine = $TAXOMACHINE_BASE_URL+
     s+oti = .*+oti = $OTI_BASE_URL+
     s+opentree_api = .*+opentree_api = $OPENTREE_API_BASE_URL+
     s+collections_api_base_url = .*+collections_api_base_url = $COLLECTIONS_API_BASE_URL+
     s+amendments_api_base_url = .*+amendments_api_base_url = $AMENDMENTS_API_BASE_URL+
     s+favorites_api_base_url = .*+favorites_api_base_url = $FAVORITES_API_BASE_URL+
     s+conflict_api = .*+conflict_api = $CONFLICT_BASE_URL+
     s+CACHED_treemachine = .*+CACHED_treemachine = $CACHED_TREEMACHINE_BASE_URL+
     s+CACHED_taxomachine = .*+CACHED_taxomachine = $CACHED_TAXOMACHINE_BASE_URL+
     s+CACHED_oti = .*+CACHED_oti = $CACHED_OTI_BASE_URL+
     s+secure_sessions_with_HTTPS = .*+secure_sessions_with_HTTPS = $SSL_CERTS_FOUND+
    " < $configfile > tmp.tmp || exit 1
mv tmp.tmp $configfile || exit 1

# Add a simple parametric router to set our default web2py app
echo "PWD (install-web2py-apps):"
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

# install ncl a C++ app needed for NEXUS, newick, NeXML -->NexSON conversion
(cd repo/opentree/curator ; ./install-ncl.sh)  || exit 1

# record the current SHA for ncl
log  Installing NCL at `cd repo/opentree/curator/ncl; git log | head -1` || exit 1

echo "Apache / web2py restart required (due to app configuration)" || exit 1

# ---------- INSTALL PYTHON REQUIREMENTS, SYMLINK APPLICATIONS ----------

(cd $APPROOT; pip install -r requirements.txt) || exit 1

(cd web2py/applications; \
    ln -sf ../../repo/$WEBAPP/webapp ./$WEBAPP; \
    ln -sf ../../repo/$WEBAPP/curator ./) || exit 1
