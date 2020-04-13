#!/bin/bash

. setup/functions.sh
set -e

# ---------- WEB2PY ----------

# Install or upgrade web2py, based on a pinned release. (See
# https://github.com/web2py/web2py/releases for all available releases.)
WEB2PY_RELEASE='2.19.1'
# N.B. We should only change WEB2PY_RELEASE after updating the modified web2py files
# listed in the section 'ROUTES AND WEB2PY PATCHES' below, and thorough testing!

mkdir -p downloads
log "ABOUT TO  web2py from git........................................................................." || exit

if [ ! -d web2py ]; then
    git clone --recursive https://github.com/web2py/web2py.git || exit
    log "Installed web2py from git........................................................................." || exit

    # clear old sessions in all web2py applications (these can cause heisenbugs in web2py upgrades)
    rm -rf repo/opentree/*/sessions/* || exit
    rm -rf repo/phylesystem-api/sessions/* || exit

    rm -rf web2py/applications/welcome  || exit
    rm -rf web2py/applications/examples  || exit
    log "Cleared old sessions in all web2py apps"  || exit
fi

# ---------- VIRTUALENV + WEB2PY + WSGI ----------

# Patch web2py's wsgihandler so that it does the equivalent of 'venv/activate'
# when started by Apache.

# See http://stackoverflow.com/questions/11758147/web2py-in-apache-mod-wsgi-with-virtualenv
# Indentation (or lack thereof) is critical
cat <<EOF >fragment.tmp
activate_this = '$PWD/venv/bin/activate_this.py'
execfile(activate_this, dict(__file__=activate_this))
import sys
sys.path.insert(0, '$PWD/web2py')
EOF

# This is pretty darn fragile!  But if it fails, it will fail big -
# the web apps won't work at all.

(head -2 web2py/handlers/wsgihandler.py && \
 cat fragment.tmp && \
 tail -n +3 web2py/handlers/wsgihandler.py) \
   > web2py/wsgihandler.py

rm fragment.tmp
