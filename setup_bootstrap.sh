TAXOMACHINE_HOME="/home/cody/phylo/taxomachine/"
TAXOMACHINE=$TAXOMACHINE_HOME"target/taxomachine-0.0.1-SNAPSHOT-jar-with-dependencies.jar"

JAVAFLAGS="-Xmx30G"

OTT_SOURCEDIR="/home/cody/phylo/ott2.1/"
OTT_TAXONOMY=$OTT_SOURCEDIR"taxonomy"
OTT_SYNONYMS=$OTT_SOURCEDIR"synonyms"
OTT_SOURCENAME="ott"

TAXOMACHINE_DB="/home/cody/phylo/data/ott21.db"

#if [ $1 = "--clean" ]; then # there seems to be a syntax error here
#	$CLEAN = true
#fi

# download ott

# download taxomachine

# compile taxomachine
if [ ! -f $TAXOMACHINE ]; then
	cd $TAXOMACHINE_HOME
	./mvn_cmdline.sh
fi

# clean the db if necessary
if [ $CLEAN ]; then
	rm -Rf TAXOMACHINE_DB
fi

# load taxonomy and make the indexes
if [ ! -f TAXOMACHINE_DB ]; then
	java $JAVAFLAGS -jar $TAXOMACHINE loadtaxsyn $OTT_SOURCENAME $OTT_TAXONOMY $OTT_SYNONYMS $TAXOMACHINE_DB
	java $JAVAFLAGS -jar $TAXOMACHINE makecontexts $TAXOMACHINE_DB
	java $JAVAFLAGS -jar $TAXOMACHINE makegenusindexes $TAXOMACHINE_DB
fi

# download neo4j

# install ott into neo4j

# download treemachine

