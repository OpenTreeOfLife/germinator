#!/bin/bash

. setup/functions.sh || exit 1
set -e

# ---------- WEB2PY ----------
echo "Begin install web2py.sh" || exit

# Install or upgrade web2py, based on a pinned release. (See
# https://github.com/web2py/web2py/releases for all available releases.)
WEB2PY_RELEASE='2.19.1'
# N.B. We should only change WEB2PY_RELEASE after updating the modified web2py files
# listed in the section 'WEB2PY PATCHES' below, and thorough testing!

mkdir -p downloads || exit 1
echo "ABOUT TO clone web2py from git" || exit

if [ ! -d web2py ]; then
    git clone --branch $WEB2PY_RELEASE --recursive https://github.com/web2py/web2py.git || exit
    echo "Installed web2py from git." || exit

    # clear old sessions in all web2py applications (these can cause heisenbugs in web2py upgrades)
    rm -rf repo/opentree/*/sessions/* || exit
    rm -rf repo/phylesystem-api/sessions/* || exit

    rm -rf web2py/applications/welcome  || exit
    rm -rf web2py/applications/examples  || exit
    echo "Cleared old sessions in all web2py apps"  || exit
fi

# ---- WEB2PY PATCHES ---
# Apply a few tweaks to vanilla web2py (updated for web2py 2.19.1)
# See comments in each patched file for details.
cp -p setup/web2py-patches/rewrite.py web2py/gluon/ || exit 1
# Update these otehr legacy patches?
##cp -p setup/web2py-patches/oauth20_account.py web2py/gluon/contrib/login_methods/ || exit 1
##cp -p setup/web2py-patches/custom_import.py web2py/gluon/ || exit 1


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
   > web2py/wsgihandler.py || exit 1

rm fragment.tmp || exit 1
