# An attempt to automate this:
#  https://github.com/OpenTreeOfLife/germinator/wiki/Setting-up-the-asterales-system

REPO=../..
ROOT_TAXON=Asterales
ROOT_TAXON_ID=1042120

all: deploy

# Fetch OTT

ott/taxonomy.tsv:
	wget http://files.opentreeoflife.org/ott/ott2.9/ott2.9.tgz
	tar xzf ott2.9.tgz

# Extract subtree of OTT rooted at chosen node (Asterales = 1042120)

subset/taxonomy.tsv: ott/taxonomy.tsv
	$(REPO)/reference-taxonomy/bin/jython $(REPO)/reference-taxonomy/util/select_from_taxonomy.py ott/ $(ROOT_TAXON) subset/
	echo version > subset/version.txt

# Get jade and ot-base (needed by taxomachine)

JADEJAR=~/.m2/repository/org/opentree/jade/0.0.1-SNAPSHOT/jade-0.0.1-SNAPSHOT.jar
$(JADEJAR):
	(cd $(REPO)/jade; ./mvn_install.sh)

OTBASEJAR=~/.m2/repository/org/opentree/ot-base/0.0.1-SNAPSHOT/ot-base-0.0.1-SNAPSHOT.jar
$(OTBASEJAR):
	(cd $(REPO)/ot-base; ./mvn_install.sh)

#TAXOJAR=~/.m2/repository/org/opentree/jade/0.0.1-SNAPSHOT/taxomachine-0.0.1-SNAPSHOT.jar
#$(TAXOJAR):
#	(cd $(REPO)/taxomachine; ./install_as_maven_artifact.sh)

# Build taxomachine neo4j database

TAXO_COMMAND=taxomachine.jar

$(TAXO_COMMAND): $(REPO)/taxomachine $(JADEJAR) $(OTBASEJAR)
	(cd $(REPO)/taxomachine; ./compile_standalone.sh)
	mv $(REPO)/taxomachine/target/taxomachine-0.0.1-SNAPSHOT-jar-with-dependencies.jar $(TAXO_COMMAND)

TAXO=java -Xmx10g -XX:-UseConcMarkSweepGC -jar $(TAXO_COMMAND)

taxomachine.db.tgz: $(TAXO_COMMAND) subset/taxonomy.tsv
	rm -rf taxomachine.db
	$(TAXO) loadtaxsyn ott subset/taxonomy.tsv subset/synonyms.tsv taxomachine.db
	$(TAXO) makecontexts taxomachine.db
	$(TAXO) makegenusindexes taxomachine.db
	tar -C taxomachine.db -czf taxomachine.db.tgz .

# Get study nexsons

synth/Source_nexsons: synth/fetch_studies.py
	mkdir -p synth.tmp
	python synth/fetch_studies.py "synth.tmp/"
	rm -rf synth/Source_nexsons
	mv synth.tmp/Source_nexsons synth/
	rmdir synth.tmp

# Build treemachine neo4j database (synthesis)
TREE_COMMAND=treemachine.jar

$(TREE_COMMAND): $(REPO)/treemachine
	(cd $(REPO)/treemachine; ./mvn_cmdline.sh)	
	mv $(REPO)/treemachine/target/treemachine-0.0.1-SNAPSHOT-jar-with-dependencies.jar $(TREE_COMMAND)

treemachine.db.tgz: $(TREE_COMMAND) synth/Source_nexsons synth/synth_procedure.py
	rm -rf treemachine.db
	python synth/synth_procedure.py \
	  "java -jar" \
	  "$(TREE_COMMAND)" \
	  "synth/" \
	  "subset/" \
	  "$(REPO)/otcetera/supertree/" \
	  "$(ROOT_TAXON_ID)" \
	  "treemachine.db" \
	  "synth.tre"
	tar -C treemachine.db -czf treemachine.db.tgz .

dbs: taxomachine.db.tgz treemachine.db.tgz

# Deploy to server
PUSH=./push.sh -c $(PWD)/subset.config
deploy_services: subset.config
	(cd ../deploy; $(PUSH))
deploy_taxomachine: taxomachine.db.tgz
	(cd ../deploy; $(PUSH) push-db    $(PWD)/taxomachine.db.tgz taxomachine)
deploy_oti: taxomachine.db.tgz
	(cd ../deploy; $(PUSH) install-db downloads/taxomachine.db.tgz oti)
deploy_index:
	(cd ../deploy; $(PUSH) index)
deploy_treemachine: treemachine.db.tgz
	(cd ../deploy; $(PUSH) push-db    $(PWD)/treemachine.db.tgz treemachine)
deploy_smasher: taxonomy.tgz synth.tre.gz
	scp -p taxonomy.tgz asterales:repo/reference-taxonomy/service/
	scp -p synth.tre.gz asterales:repo/reference-taxonomy/service/
	(cd ../deploy; $(PUSH) smasher)

taxonomy.tgz: subset
	tar cvzf taxonomy.tgz subset

synth.tre.gz: synth.tre
	gzip -c synth.tre >synth.tre.gz

deploy: deploy_services deploy_taxomachine deploy_oti deploy_index deploy_treemachine deploy_smasher
