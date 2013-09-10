# TODO: record output to log file

JAVAFLAGS="-Xms4G -Xmx30G"
HELPTEXT="usage:\nsetup_taxomachine.sh <options>\n\t[--clean-db]\n\t[--setup-db]\n\t[--download-ott]\n\t[--setup-server]\n\t[--restart-server]\n\t[--test]\n\t[--force]\n\t[--update-taxomachine]\n\t[--recompile-taxomachine]\n\t[--recompile-plugin]\n\t[-ott-version <2.0|2.1|2.2>]\n\t[-prefix <path>]\n\n"

while [ $# -gt 0 ]; do
	case "$1" in
		--clean-db) CLEANDB=true;;
		--setup-db) SETUP_DB=true;;
		--download-ott) DOWNLOAD_OTT=true;;
		--setup-server) SETUP_SERVER=true;;
		--restart-server) RESTART_SERVER=true;;
		--test) TEST=true;;
		--force) FORCE=true;;
		--update-taxomachine) UPDATE=true;;
		--recompile-taxomachine) RECOMPILE=true;;
		--recompile-plugin) RECOMPILE_PLUGIN=true;;
		-ott-version)
			shift
			case "$1" in
				2.0) VERSION="ott2.0";;
				2.1) VERSION="ott2.1";;
				2.2) VERSION="ott2.2";;
				*) printf "version $1 not recognized.";; 
			esac;;
		-prefix) shift; PFSET=true; PREFIX="$1";;
		--help) printf "$HELPTEXT"; exit 0;;
		*) printf "\nunrecognized argument: $1.\n"; printf "$HELPTEXT"; exit 1;
	esac
	shift
done

JAVA=java
if [ $TEST ]; then
	printf "\njust testing. java commands will be printed instead of executed\n"
	$JAVA="java"
fi

if [ ! $VERSION ]; then
	VERSION="ott2.2"
	printf "\nwill attempt to use $VERSION\n"
fi

if [ ! $PFSET ]; then
	PREFIX="$HOME/phylo"
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

JARSDIR="$PREFIX/jars"
if [ ! -d $JARSDIR ]; then
    mkdir $JARSDIR
fi

OTT_SOURCENAME="ott"
OTT_DOWNLOADDIR=$PREFIX"/data"
if [ ! -d $OTT_DOWNLOADDIR ]; then
	mkdir $OTT_DOWNLOADDIR
fi

if [ $DOWNLOAD_OTT ]; then

	printf "\ntaxonomy $VERSION will be downloaded\n"
	printf "installing $VERSION taxonomy at: $OTT_DOWNLOADDIR\n"

	# removing existing copy
	cd $OTT_DOWNLOADDIR
	rm -Rf $VERSION $VERSION.tgz

	# download and decompress ott
	wget "http://dev.opentreeoflife.org/ott/$VERSION.tgz"
	tar -xvf $VERSION.tgz
	
fi 

OTT_SOURCEDIR="$OTT_DOWNLOADDIR/$VERSION"
if [ ! -d $OTT_SOURCEDIR ]; then
	printf "\ncan\'t find $OTT_SOURCEDIR. use --download-ott to download a copy\n"
	exit
fi
printf "\nusing $VERSION taxonomy at: $OTT_SOURCEDIR\n"

OTT_TAXONOMY=$OTT_SOURCEDIR"/taxonomy"
OTT_SYNONYMS=$OTT_SOURCEDIR"/synonyms"

# download taxomachine
TAXOMACHINE_HOME=$PREFIX"/taxomachine"
if [ ! -d $TAXOMACHINE_HOME ]; then
	printf "\ninstalling taxomachine at: $TAXOMACHINE_HOME\n"
	git clone git@github.com:OpenTreeOfLife/taxomachine.git
fi
printf "\nusing taxomachine at: $TAXOMACHINE_HOME\n"

# pull from the git repo and remove the binary if updating is turned on
TAXOMACHINE_JAR="taxomachine-0.0.1-SNAPSHOT-jar-with-dependencies.jar"
TAXOMACHINE_COMPILE_LOCATION="$TAXOMACHINE_HOME/target/$TAXOMACHINE_JAR"
TAXOMACHINE_INSTALL_LOCATION="$JARSDIR/$TAXOMACHINE_JAR"

if [ $UPDATE ]; then
	cd $TAXOMACHINE_HOME
	git pull origin master
	rm -f $TAXOMACHINE_INSTALL_LOCATION
fi

# just remove the binary if we want recompile
if [ $RECOMPILE ]; then
	rm -f $TAXOMACHINE_INSTALL_LOCATION
fi

# compile taxomachine if necessary
if [ ! -f $TAXOMACHINE_INSTALL_LOCATION ]; then
	cd $TAXOMACHINE_HOME
	sh mvn_cmdline.sh
	mv $TAXOMACHINE_COMPILE_LOCATION $TAXOMACHINE_INSTALL_LOCATION
fi

TAXOMACHINE_COMMAND="$JAVA $JAVAFLAGS -jar $TAXOMACHINE_INSTALL_LOCATION \"\$@\""
TAXOMACHINE_START_SCRIPT="/usr/local/bin/taxomachine"
INSTALL_START_SCRIPT=true
if [ -f $TAXOMACHINE_START_SCRIPT ]; then
    if cat $TAXOMACHINE_START_SCRIPT | grep '$TAXOMACHINE_COMMAND' ; then
        INSTALL_START_SCRIPT=false
    fi
fi

if [ $INSTALL_START_SCRIPT = true ]; then
    echo $TAXOMACHINE_COMMAND > $TAXOMACHINE_START_SCRIPT
    chmod +x $TAXOMACHINE_START_SCRIPT
fi

if [ ! -f $TAXOMACHINE_START_SCRIPT ]; then
    printf "\nthe taxomachine start script could not be installed. do you need to sudo? quitting\n"
    exit
fi

# prepare for dealing with the neo4j server if necessary
TAXO_NEO4J_HOME="$PREFIX/neo4j-community-1.9.3-taxomachine"
TAXO_NEO4J_DAEMON="$TAXO_NEO4J_HOME/bin/neo4j"

# clean the db if necessary
TAXOMACHINE_DB="$OTT_DOWNLOADDIR/$VERSION.db"
if [ $CLEANDB ]; then
    if [ -f $TAXO_NEO_DAEMON ]; then
        printf "\nattempting to shut down the neo4j server\n"
        $TAXO_NEO4J_DAEMON stop
    fi
	printf "\nremoving the existing database at: $TAXOMACHINE_DB\n"
	rm -Rf $TAXOMACHINE_DB
fi

# load taxonomy and make the indexes
if [ $SETUP_DB ]; then

	# require explicit instructions to remove existing db
	if [ -d $TAXOMACHINE_DB ]; then
		printf "\ndatabase at $TAXOMACHINE_DB already exists. to rebuild it, use --clean-db --setup-db\n"
		exit
	fi

#	echo "$TAXOMACHINE_START_SCRIPT loadtaxsyn $OTT_SOURCENAME $OTT_TAXONOMY $OTT_SYNONYMS $TAXOMACHINE_DB"
#    echo "$TAXOMACHINE_START_SCRIPT makecontexts $TAXOMACHINE_DB"
#	echo "$TAXOMACHINE_START_SCRIPT makegenusindexes $TAXOMACHINE_DB"

	$TAXOMACHINE_START_SCRIPT loadtaxsyn $OTT_SOURCENAME $OTT_TAXONOMY $OTT_SYNONYMS $TAXOMACHINE_DB	
	$TAXOMACHINE_START_SCRIPT makecontexts $TAXOMACHINE_DB
	$TAXOMACHINE_START_SCRIPT makegenusindexes $TAXOMACHINE_DB
fi

# start the server
if [ $SETUP_SERVER ]; then

    # download neo4j if necessary
    if [ ! -d $TAXO_NEO4J_HOME ]; then
        cd "$HOME/Downloads"
        wget "http://download.neo4j.org/artifact?edition=community&version=1.9.3&distribution=tarball&dlid=2600508"
        tar -xvf "artifact?edition=community&version=1.9.3&distribution=tarball&dlid=2600508"
        printf "\ninstalling neo4j instance for taxomachine at: $TAXO_NEO4J_HOME\n"
        mv neo4j-community-1.9.3 $TAXO_NEO4J_HOME
    fi
    
    # point the server at the taxomachine db location
    TAXOMACHINE_DB_ASSIGNMENT="org.neo4j.server.database.location=$TAXOMACHINE_DB"
    COMMENT="###############################################################\n# location for taxomachine db, original location settings are in original file"
    SERVER_PROPERTIES="$TAXO_NEO4J_HOME/conf/neo4j-server.properties"
    
    if cat $SERVER_PROPERTIES | grep -q $TAXOMACHINE_DB_ASSIGNMENT ; then
        printf "\nServer set correctly to use db at $TAXOMACHINE_DB\n"
    else
        printf "\nServer config will be changed to use db at $TAXOMACHINE_DB\n"

        ORIG_SERVER_PROPERTIES="$SERVER_PROPERTIES.original"
        mv "$SERVER_PROPERTIES" "$ORIG_SERVER_PROPERTIES"
        printf "$COMMENT\n$TAXOMACHINE_DB_ASSIGNMENT\n\n" > "$SERVER_PROPERTIES"
        grep -v "org.neo4j.server.database.location" "$ORIG_SERVER_PROPERTIES" >> "$SERVER_PROPERTIES"

    fi

    #### TODO: switch the port to 7476. This is going to require neo4j enterprise

fi

printf "\nusing neo4j instance for taxomachine at: $TAXO_NEO4J_HOME\n"

# install the plugin if necessary
PLUGIN="opentree-neo4j-plugins-0.0.1-SNAPSHOT.jar"
PLUGIN_INSTALL_LOCATION="$TAXO_NEO4J_HOME/plugins/"

# just remove the binary if we want recompile
if [ $RECOMPILE_PLUGIN ]; then    
    rm -f $PLUGIN_INSTALL_LOCATION
fi

# recompile if the plugin is not there    
if [ ! -f $PLUGIN_INSTALL_LOCATION ]; then
    cd $TAXOMACHINE_HOME	
    sh mvn_serverplugins.sh
    PLUGIN_COMPILE_LOCATION="$TAXOMACHINE_HOME/target/$PLUGIN"
    mv "$PLUGIN_COMPILE_LOCATION" "$PLUGIN_INSTALL_LOCATION"
fi

if [ $RESTART_SERVER ]; then
    $TAXO_NEO4J_DAEMON restart
fi

