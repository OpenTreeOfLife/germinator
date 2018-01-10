#!/bin/bash

. setup/functions.sh

CONTROLLER=$1
WHICH_APP=$2
FORCE_COMPILE=$3

# Will not run on AWS free tier.  Recommended at least 60G disk and 16G RAM.

# Temporary locations for things downloaded from web.  Can delete the
# downloads directory after server is up and running.  You can delete
# the repo as well; the running neo4j doesn't access it.

mkdir -p downloads
mkdir -p repo

# This is absolutely the wrong way to handle dependencies.
# A rewrite is in order, perhaps using 'make'.
dependency_changed=no

# ---------- NEO4J ----------
if [ ! -r downloads/neo4j.tgz ]; then
    wget --no-verbose -O downloads/neo4j.tgz "http://dist.neo4j.org/neo4j-community-1.9.5-unix.tar.gz?edition=community&version=1.9.5&distribution=tarball&dlid=2824963"
fi

# ---------- DEPENDENCIES ----------
# Set up neo4j services

if git_refresh FePhyFoFum jade || \
        [ ! -d ~/.m2/repository/org/opentree/jade ]; then
    dependency_changed=yes
    (cd repo/jade; sh mvn_install.sh)
fi

if git_refresh OpenTreeOfLife ot-base || \
        [ ! -d ~/.m2/repository/org/opentree/ot-base ] || \
        [ $dependency_changed = "yes" ]; then
    dependency_changed=yes
    (cd repo/ot-base; sh mvn_install.sh)
fi

# I think the following is only for the benefit of oti
if [ $WHICH_APP = oti ]; then
    if git_refresh OpenTreeOfLife taxomachine || \
            [ ! -d ~/.m2/repository/org/opentree/taxomachine ] || \
            [ $dependency_changed = "yes" ]; then
        dependency_changed=yes
        (cd repo/taxomachine; sh install_as_maven_artifact.sh)
        # Kludge to force re-creation of the plugin as well. It would
        # be better to handle dependencies using 'make' or something
        # like that.
        rm -f neo4j-taxomachine/plugins/taxomachine*.jar
    fi
fi

# ---------- NEO4J WITH TREEMACHINE / TAXOMACHINE / OTI PLUGINS ----------

#jar=opentree-neo4j-plugins-0.0.1-SNAPSHOT.jar
VERSION=0.0.1-SNAPSHOT

function make_neo4j_instance {
    
    APP=$1
    APORT=$2
    BPORT=$3
    jar=$APP-neo4j-plugins-$VERSION.jar
    echo "installing plugin for" $APP

    # Create a copy of neo4j for this app
    if [ ! -x neo4j-$APP/bin/neo4j ] ; then
        echo "installing neo4j for" $APP
        tar xzf downloads/neo4j.tgz
        mv neo4j-community-* neo4j-$APP
    fi

    # Get plugin from git repository & compile it
    if git_refresh OpenTreeOfLife $APP || \
            [ ! -r neo4j-$APP/plugins/$jar ] || \
            [ $FORCE_COMPILE = "yes" ] ||\
            [ $dependency_changed = "yes" ]; then
    
        echo "attempting to recompile "$APP" plugins"
        # Create and install the plugins .jar file
        if [ $APP = taxomachine ]; then
            (cd repo/$APP; ./compile_server_plugins.sh)
        else
            (cd repo/$APP; ./mvn_serverplugins.sh)
        fi
    fi

    if false; then
        # NOTE that we now use systemd to manage neo4j instances as daemons, so
        # (re)starting neo4j will be take care of later.

        # Stop any running server.  (The database may be empty at this point.)
        # Do this after compilation, so as to minimize system downtime.
        # N.B. We do this regardless of whether there has been a change in its
        # repo, since otherwise apache may fail to proxy requests to this app.
        if ./neo4j-$APP/bin/neo4j status; then
            # this is just a one-time task as we shut down an old-style neo4j
            # instance still running on this server.
            echo "Stopping (old) standalone $APP neo4j server"
            ./neo4j-$APP/bin/neo4j stop
        fi

        # There was some question as to whether the above code worked.
        # I'm keeping the following replacement code for a while, just in case.
        # N.B. The 'neo4j status' command returns a phrase like this (for a stopped instance):
        #    Neo4j Server is not running
        # ... or this (for a running instance):
        #    Neo4j Server is running at pid #####
        if [[ "`./neo4j-$APP/bin/neo4j status`" =~ "is running" ]]; then
            echo "Stopping $APP neo4j server"
            ./neo4j-$APP/bin/neo4j stop
        fi
    fi

    # Move new plugin code into place
    cp -p -f repo/$APP/target/$jar neo4j-$APP/plugins/

    # Replace defaults ports with ports appropriate for this application
    # The installed neo4j initially has:
    #    org.neo4j.server.webserver.port=7474
    #    org.neo4j.server.webserver.https.port=7473
    cat neo4j-$APP/conf/neo4j-server.properties | \
    sed s+7474+$APORT+ | \
    sed s+7473+$BPORT+ | \
    sed s+org.neo4j.server.http.log.enabled=false+org.neo4j.server.http.log.enabled=true+ \
      > props.tmp
    mv props.tmp neo4j-$APP/conf/neo4j-server.properties

    # Now wait for its persistent neo4j daemon to (re)start...
}

# TBD: The port numbers should be configurable in the config file

case $WHICH_APP in
    oti)         make_neo4j_instance oti         7478 7477 ;;
    treemachine) make_neo4j_instance treemachine 7474 7473 ;;
    taxomachine) make_neo4j_instance taxomachine 7476 7475 ;;
esac

log "Finished installing $WHICH_APP plugin"

# Apache needs to be restarted
