JAVAFLAGS="-Xmx30G"
HELPTEXT="usage:\nsetup_taxomachine.sh <options>\n\t[--clean-db]\n\t[--setup-db]\n\t[--download-ott]\n\t[--test]\n\t[--force]\n\t[--update-taxomachine]\n\t[--recompile-taxomachine]\n\t[-ott-version <2.0|2.1|2.2>]\n\t[-prefix <path>]\n\n"

while [ $# -gt 0 ]; do
	case "$1" in
		--clean-db) CLEANDB=true;;
		--setup-db) SETUP_DB=true;;
		--download-ott) DOWNLOAD_OTT=true;;
		--test) TEST=true;;
		--force) FORCE=true;;
		--update-taxomachine) UPDATE=true;;
		--recompile-taxomachine) RECOMPILE=true;;
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
	PREFIX="$HOME/phylo/"
	if [ ! $FORCE ]; then
		printf "\nprefix is not set. all files will be downloaded to $PREFIX. continue? y/n:"
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
PREFIX=$(pwd)"/"
printf "\ninstalling files at: $PREFIX\n"

OTT_SOURCENAME="ott"
OTT_DOWNLOADDIR=$PREFIX"data/"
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

OTT_SOURCEDIR="$OTT_DOWNLOADDIR$VERSION/"
if [ ! -d $OTT_SOURCEDIR ]; then
	printf "\ncan\'t find $OTT_SOURCEDIR. use --download-ott to download a copy\n"
	exit
fi
printf "\nusing $VERSION taxonomy at: $OTT_SOURCEDIR\n"

OTT_TAXONOMY=$OTT_SOURCEDIR"taxonomy"
OTT_SYNONYMS=$OTT_SOURCEDIR"synonyms"

# download taxomachine
TAXOMACHINE_HOME=$PREFIX"taxomachine/"
if [ ! -d $TAXOMACHINE_HOME ]; then
	printf "\ninstalling taxomachine at: $TAXOMACHINE_HOME\n"
	git clone git@github.com:OpenTreeOfLife/taxomachine.git
fi
printf "\nusing taxomachine at: $TAXOMACHINE_HOME\n"

# pull from the git repo and remove the binary if updating is turned on
TAXOMACHINE=$TAXOMACHINE_HOME"target/taxomachine-0.0.1-SNAPSHOT-jar-with-dependencies.jar"
if [ $UPDATE ]; then
	cd $TAXOMACHINE_HOME
	git pull origin master
	rm -f $TAXOMACHINE
fi

# just remove the binary if we want recompile
if [ $RECOMPILE ]; then
	rm -f $TAXOMACHINE
fi

# compile taxomachine if necessary
if [ ! -f $TAXOMACHINE ]; then
	cd $TAXOMACHINE_HOME	
	./mvn_cmdline.sh
fi

# clean the db if necessary
TAXOMACHINE_DB=$OTT_DOWNLOADDIR$VERSION".db"
if [ $CLEANDB ]; then
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
	
	$JAVA $JAVAFLAGS -jar $TAXOMACHINE loadtaxsyn $OTT_SOURCENAME $OTT_TAXONOMY $OTT_SYNONYMS $TAXOMACHINE_DB
	$JAVA $JAVAFLAGS -jar $TAXOMACHINE makecontexts $TAXOMACHINE_DB
	$JAVA $JAVAFLAGS -jar $TAXOMACHINE makegenusindexes $TAXOMACHINE_DB
fi

# download neo4j

# setup the neo4j instance to use the taxomachine db
