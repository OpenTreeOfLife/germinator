#!/bin/bash

# This script runs as the admin user, which has sudo privileges

# Expect a string with one or more names in it; each should correspond to a
# command or component as used in the deployment script `push.sh`
COMMAND_OR_COMPONENTS=$1

for TEST_NAME in $COMMAND_OR_COMPONENTS; do 
    echo "... testing this command or component for daemons: [$TEST_NAME]"
    # Some components and commands will deploy services that need daemons for
    # monitoring, to hand reboots, etc.
    case $TEST_NAME in
        # Commands that require daemons
        push-db | pushdb)
            ## push_neo4j_db $*
            # TODO: Monitor and restart neo4j?
            ;;
        install-db)
            ## if [ $# = 2 ]; then
            ##     install_neo4j_db $*
            ##     # restart apache to clear the RAM cache (stale results)
            ##     restart_apache=yes
            ## else
            ##     err "Wrong number of arguments to install-db" $*
            ## fi
            # TODO: Monitor and restart neo4j?
            ;;
        # Commands that don't need daemons (or already install them)
        apache | index  | indexoti | index-db | echo | none)
            echo "    No daemons required for command [$TEST_NAME]"
            ;;

        # Components that require daemons
        opentree)
            ## push_webapps
            ## restart_apache=yes
            # TODO: Sweep old sessions in its web2py apps!
            ;;
        phylesystem-api | api)
            ## Customize the web2py session-cleanup template for this webapp
            echo "    Adding daemon to remove old web2py sessions [$TEST_NAME]..."
            echo "      whoami [`whoami`]"
            echo "      hostname [`hostname`]"
            echo "      pwd [`pwd`]"
            
            WEB2PY_APP_DIRNAME=phylesystem
            SESSION_CLEANER_INIT_SCRIPT=cleanup-sessions-${WEB2PY_APP_DIRNAME}
            OTHOME=/home/opentree
            sudo cp "$OTHOME"/setup/cleanup-sessions-WEB2PYAPPNAME.lsb-template /etc/init.d/$SESSION_CLEANER_INIT_SCRIPT
            # N.B. there's also a generic linux init.d script that doesn't rely on LSB:
            # cp "$OTHOME"/setup/cleanup-sessions-WEB2PYAPPNAME.generic-template /etc/init.d/$SESSION_CLEANER_INIT_SCRIPT
            
            pushd .
                cd /etc/init.d
                # TODO: Set owner and permissions for this script?
                ##sudo chown ...
                ##sudo chmod 755 $SESSION_CLEANER_INIT_SCRIPT
                # Give it the proper directory name for this web2py app
                sudo sed -i -e "s+WEB2PY_APP_DIRNAME+$WEB2PY_APP_DIRNAME+g" $SESSION_CLEANER_INIT_SCRIPT
                # TODO: Customize its DAEMONOPTS?
                # Register this daemon with init.d and start it now
                sudo /usr/sbin/update-rc.d $SESSION_CLEANER_INIT_SCRIPT defaults
                # N.B. This should start automatically upon installation!
            popd
            echo "    Daemon added! [$TEST_NAME]"
            ;;
        oti)
            ## push_neo4j oti
            # TODO: Monitor and restart neo4j?
            ;;
        treemachine)
            ## push_neo4j treemachine
            ## # restart apache to clear the RAM cache (stale results)
            ## restart_apache=yes
            # TODO: Monitor and restart neo4j?
            ;;
        taxomachine)
            ## push_neo4j taxomachine
            ## # restart apache to clear the RAM cache (stale results)
            ## restart_apache=yes
            # TODO: Monitor and restart neo4j?
            ;;
        # Components that don't need daemons (or already install them)
        smasher | otcetera | push_otcetera)
            echo "    No daemons required for component [$TEST_NAME]"
            ;;

        *)
            echo "    Name not found in script '$0'! [$TEST_NAME]"
            ;;
    esac
done   # end of TEST_NAME loop

echo "done installing daemons!"

# Salvaged from original implementation:
## # One of these commands hangs after printing "(Re)starting web2py session sweeper..."
## # so for now I'm going to disable this code.  See 
## # https://github.com/OpenTreeOfLife/opentree/issues/845
## 
## echo "(Re)starting web2py session sweeper..."
## # The sessions2trash.py utility script runs in the background, deleting expired
## # sessions every 5 minutes. See documentation at
## #   http://web2py.com/books/default/chapter/29/13/deployment-recipes#Cleaning-up-sessions
## # Find and kill any sweepers that are already running
## sudo pkill -f sessions2trash
## # Now run a fresh instance in the background for each webapp
## sudo nohup python $OPENTREE_HOME/web2py/web2py.py -S opentree -M -R $OPENTREE_HOME/web2py/scripts/sessions2trash.py &
## # NOTE that we allow up to 24 hrs(!) before study-curation sessions will expire
## sudo nohup python $OPENTREE_HOME/web2py/web2py.py -S curator -M -R $OPENTREE_HOME/web2py/scripts/sessions2trash.py --expiration=86400 &
