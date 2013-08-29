JAVAFLAGS="-Xmx30G"

while [ $# -gt 0 ]; do
	case "$1" in
		--clean-db) CLEANDB=true;;
		--setup-db) SETUP_DB=true;;
		--download-ott) DOWNLOAD_OTT=true;;
		--test) TEST=true;;
		--force) FORCE=true;;
		-ott-version)
			shift
			case "$1" in
				2.1) VERSION="ott2.1";;
				2.2) VERSION="ott2.2";;
				*) echo "version $1 not recognized.";; 
			esac;;
		-prefix) shift; PFSET=true; PREFIX="$1";;
		-*) echo "usage: setup_taxomachine.sh [--clean-db] [--setup-db] [--download-ott] [--test] [--force] [-ott-version <2.1|2.2>] [-prefix <path>]";;
	esac
	shift
done

JAVA=java
if [ $TEST ]; then
	echo "\njust testing. java commands will be echoed instead of executed"
	$JAVA="java"
fi

if [ ! $VERSION ]; then
	VERSION="ott2.2"
	echo "\nwill attempt to use $VERSION"
fi

if [ ! $PFSET ]; then
	PREFIX="$HOME/phylo/"
	if [ ! $FORCE ]; then
		echo "\nprefix is not set. all files will be downloaded to $PREFIX. continue? y/n:"
		while [ true ]; do
			read RESP
			case "$RESP" in
				n) exit;;
				y) break;;
				*) echo "unrecognized input. uze ^C to exit script";;
			esac
		done
	fi
fi

if [ ! -d $PREFIX ]; then
	mkdir $PREFIX
fi
cd $PREFIX
PREFIX=$(pwd)"/"
echo "\ninstalling files at: $PREFIX"

OTT_SOURCENAME="ott"
OTT_DOWNLOADDIR=$PREFIX"data/"
if [ ! -d $OTT_DOWNLOADDIR ]; then
	mkdir $OTT_DOWNLOADDIR
fi

if [ $DOWNLOAD_OTT ]; then

	echo "\ntaxonomy $VERSION will be downloaded"
	echo "installing $VERSION taxonomy at: $OTT_DOWNLOADDIR"

	# removing existing copy
	cd $OTT_DOWNLOADDIR
	rm -Rf $VERSION $VERSION.tgz

	# download and decompress ott
	wget "http://dev.opentreeoflife.org/ott/$VERSION.tgz"
	tar -xvf $VERSION.tgz
	
fi 

OTT_SOURCEDIR="$OTT_DOWNLOADDIR$VERSION/"
if [ ! -d $OTT_SOURCEDIR ]; then
	echo "can't find $OTT_SOURCEDIR. use --download to download a copy"
	exit
fi
echo "using $VERSION taxonomy at: $OTT_SOURCEDIR"

OTT_TAXONOMY=$OTT_SOURCEDIR"taxonomy"
OTT_SYNONYMS=$OTT_SOURCEDIR"synonyms"

# download taxomachine
TAXOMACHINE_HOME=$PREFIX"taxomachine/"
if [ ! -d $TAXOMACHINE_HOME ]; then
	echo "installing taxomachine at: $TAXOMACHINE_HOME"
	git clone git@github.com:OpenTreeOfLife/taxomachine.git
fi
echo "using taxomachine at: $TAXOMACHINE_HOME"

# compile taxomachine if necessary
TAXOMACHINE=$TAXOMACHINE_HOME"target/taxomachine-0.0.1-SNAPSHOT-jar-with-dependencies.jar"
if [ ! -f $TAXOMACHINE ]; then
	cd $TAXOMACHINE_HOME
	./mvn_cmdline.sh
fi

# clean the db if necessary
TAXOMACHINE_DB=$OTT_DOWNLOADDIR$VERSION".db"
if [ $CLEANDB ]; then
	echo "removing the existing database at: $TAXOMACHINE_DB"
	rm -Rf TAXOMACHINE_DB
fi

# load taxonomy and make the indexes
if [ $SETUP_DB ]; then

	# require explicit instructions to remove existing db
	if [ -d $TAXOMACHINE_DB ]; then
		echo "database at $TAXOMACHINE_DB already exists. to rebuild it, use --clean-db --setup-db"
		exit
	fi
	
	$JAVA $JAVAFLAGS -jar $TAXOMACHINE loadtaxsyn $OTT_SOURCENAME $OTT_TAXONOMY $OTT_SYNONYMS $TAXOMACHINE_DB
	$JAVA $JAVAFLAGS -jar $TAXOMACHINE makecontexts $TAXOMACHINE_DB
	$JAVA $JAVAFLAGS -jar $TAXOMACHINE makegenusindexes $TAXOMACHINE_DB
fi

# download neo4j

# setup the neo4j instance to use the taxomachine db
