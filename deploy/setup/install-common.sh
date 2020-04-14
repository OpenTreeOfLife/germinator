#!/bin/bash

# Common setup for all web2py applications (opentree, curator, phylesystem-api)

if [ "$#" -ne 2 ]; then
    echo "install-common.sh WNA (expecting 2)"
    exit 1
fi

OPENTREE_DEFAULT_APPLICATION=$1
export CONTROLLER=$2

. setup/functions.sh  || exit 1

echo "Installing web2py common" || exit 1

bash setup/install-web2py.sh || exit 1

echo "...fetching opentree repo..." || exit 1
git_refresh OpenTreeOfLife opentree || true

# requirements list ?

(cd web2py/applications; \
    ln -sf ../../repo/$WEBAPP/common ./)  || exit 1

# Apply our patches to vanilla web2py 2.8.2
# See comments in each patched file for details.
cp -p repo/opentree/oauth20_account.py web2py/gluon/contrib/login_methods/ || exit 1
cp -p repo/opentree/rewrite.py web2py/gluon/ || exit 1
cp -p repo/opentree/custom_import.py web2py/gluon/ || exit 1

TMP=/tmp/tmp.tmp
echo default_application should be "$OPENTREE_DEFAULT_APPLICATION" || exit 1
sed -e "s+default_application='.*'+default_application='$OPENTREE_DEFAULT_APPLICATION'+" \
   repo/opentree/SITE.routes.py >$TMP || exit 1
cp $TMP web2py/routes.py || exit 1
rm $TMP || exit 1
grep default_ web2py/routes.py || exit 1

# Kludge in case OPENTREE_DEFAULT_APPLICATION is set to 'welcome' or (more likely) 'phylesystem'
cp -p repo/opentree/webapp/static/robots.txt web2py/applications/welcome/static/ || exit 1
mkdir -p web2py/applications/phylesystem/static || exit 1
cp -p repo/opentree/webapp/static/robots.txt web2py/applications/phylesystem/static/ || exit 1
