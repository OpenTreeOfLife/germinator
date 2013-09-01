JAVAFLAGS="-Xmx30G"
HELPTEXT="usage:\nsetup_otu.sh <options>\\n\\t[--clean-db]\n\t[--test] (not yet)\n\t[--force]\n\t[--update-otu]\n\t[--recompile-otu]\n\t[--restart-neo4j]\n\t[--restart-otu]\n\t[-prefix <path>]\n\n"

while [ $# -gt 0 ]; do
	case "$1" in
		--clean-db) CLEANDB=true;;
		--test) TEST=true;;
		--force) FORCE=true;;
		--update-otu) UPDATE=true;;
		--recompile-otu) RECOMPILE=true;;
		--restart-neo4j) RESTART_NEO4J=true;;
		--restart-otu) RESTART_OTU=true;;
		-prefix) shift; PREFIX="$1";;
		--help) printf "$HELPTEXT"; exit 0;;
		*) printf "\nunrecognized argument: $1.\n"; printf "$HELPTEXT"; exit 1;
	esac
	shift
done

if [ ! $PREFIX ]; then
	PREFIX="$HOME/phylo" # should fix the taxomachine script to put slashes in when dirs are appended
	if [ ! $FORCE ]; then
		printf "\nprefix is not set. the default prefix $PREFIX will be used. continue? y/n:"
		while [ true ]; do
			read RESP
			case "$RESP" in
				n) exit;;
				y) break;;
				*) printf "unrecognized input. uze ^C to exit script";;
			esac
		done
	fi
fi

if [ ! -d $PREFIX ]; then
	mkdir $PREFIX
fi
cd $PREFIX
PREFIX=$(pwd)
printf "\nworking at prefix $PREFIX\n"

if [ $OSTYPE = "linux-gnu" ]; then
    echo "linux"
    LINUX=true

    # get pip and libevent
#    apt-get install python-dev
#    apt-get install python-pip
#    apt-get install libevent-dev

elif [ $OSTYPE = "darwin12" ]; then
    echo "mac"
    MAC=true
#    exit
    # for mac, we need homebrew to get pip to get grequests, soo...
    # first install homebrew
    
#    if [ ! brew ]; then
#        ruby -e "$(curl -fsSL https://raw.github.com/mxcl/homebrew/go)"
#        brew doctor
#    fi

    # use brew to get python and libevent (required for gevent)
#    brew install python --framework
#    brew install libevent
    
    ### On MacOS X 10.8, you must be running Xcode 4.4+ and you must have installed
    ### the command line tools for the following pip install to work properly.
    ### See: http://stackoverflow.com/questions/11716107/gcc-4-2-error-on-mac-os-x-mountain-lion-unable-to-install-some-packages-with-pi

fi

# install virtualenv
#pip install virtualenv # don't think this is necessary

# ok, now we can use pip to install grequests
#pip install grequests

### we do not seem to need grequests!

OTU_NEO4J_HOME="$PREFIX/neo4j-community-1.9.3-otu"
OTU_NEO4J_DAEMON="$OTU_NEO4J_HOME/bin/neo4j"

# download neo4j if necessary
if [ ! -d $OTU_NEO4J_HOME ]; then
    cd "$HOME/Downloads"
    wget "http://download.neo4j.org/artifact?edition=community&version=1.9.3&distribution=tarball&dlid=2600508"
    tar -xvf "artifact?edition=community&version=1.9.3&distribution=tarball&dlid=2600508"
    printf "\ninstalling neo4j instance for otu at: $OTU_NEO4J_HOME\n"
    mv neo4j-community-1.9.3 $OTU_NEO4J_HOME
fi
printf "\nusing neo4j instance for otu at: $OTU_NEO4J_HOME\n"

### need to install git if not already present
### need to install maven if not already present

cd $PREFIX
OTU_HOME="$PREFIX/otu"

# clone the otu repo if necessary
if [ ! -d $OTU_HOME ]; then
    printf "\ninstalling otu at: $OTU_HOME\n"
    git clone git@github.com:chinchliff/otu.git
fi
printf "\nusing otu at: $OTU_HOME\n"

if [ $UPDATE ]; then
    printf "\ngetting latest updates from github master\n"
    cd $OTU_HOME
    git pull origin master
fi
printf "\nusing otu at: $OTU_HOME\n"

cd $OTU_HOME
OTU_PLUGIN_INSTALL_LOC="$OTU_NEO4J_HOME/plugins/otu-0.0.1-SNAPSHOT.jar"
#echo $OTU_PLUGIN_INSTALL_LOC
#exit

# remove previous plugin if requested
if [ $RECOMPILE ] || [ $UPDATE ]; then
    rm -Rf $OTU_PLUGIN_INSTALL_LOC
fi

# recompile plugin if necessary
if [ ! -f $OTU_PLUGIN_INSTALL_LOC ]; then
    ./mvn_serverplugins.sh
    mv target/otu-0.0.1-SNAPSHOT.jar $OTU_PLUGIN_INSTALL_LOC
fi

OTU_DB="$OTU_NEO4J_HOME/data/graph.db"
if [ $CLEANDB ]; then
	printf "\nremoving the existing database at: $OTU_DB\n"
	rm -Rf $OTU_DB
fi

if [ $RESTART_NEO4J ]; then
    # start the neo4j. cannot have other running neo4j instances or this will fail!
    $OTU_NEO4J_DAEMON restart
fi

if [ $RESTART_OTU ]; then
    # open the tool in the web browser
    if [ $LINUX ]; then
        xdg-open http://localhost:8000/
    fi

    # start the webserver (from the views directory -- this is important for redirects)
    cd views
    ./server.py
fi