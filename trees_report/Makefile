#  $^ = all prerequisites
#  $< = first prerequisite
#  $@ = file name of target

# Parent directory for github repo clones
REPOS=../..

# How to invoke jython (with smasher built in)
JYTHON=$(REPOS)/reference-taxonomy/bin/jython

# Location of synthesis products (output/ directory)
#SYNTH=$(REPOS)/files.opentreeoflife.org/synthesis/opentree5.0/opentree5.0/output
SYNTH=/Users/karen/Documents/opentreeoflife/data/synthesis/opentree5.0/output

all: trees_report.csv

trees_report.csv: shards/phylesystem-1 trees_report.py \
	   work/conflict.csv work/synthesis_tree_list.csv work/taxa_in_synthesis.txt
	PEYOTL_CONFIG_FILE=dot_peyotl python trees_report.py $@

shards/phylesystem-1:
	mkdir -p shards
	ln -s ../$(REPOS)/phylesystem-1 shards/

conflict: work/conflict.csv

work/conflict.csv: conflict.py shards/phylesystem-1
	@mkdir -p work
	$(JYTHON) conflict.py \
	  --out $@ \
	  --shard shards/phylesystem-1 \
	  --ref $(SYNTH)/labelled_supertree/labelled_supertree.tre

# smaller, for testing
work/conflict_small.csv: conflict.py
	@mkdir -p work
	$(JYTHON) conflict.py \
	  --out $@ \
	  --shard $(REPOS)/asterales-phylesystem \
	  --ref $(REPOS)/reference-taxonomy/registry/aster-synth4/

work/synthesis_tree_list.csv: make_synthesis_tree_list.py
	@mkdir -p work
	python make_synthesis_tree_list.py $(REPOS)/collections-1 work/synthesis_tree_list.csv

work/taxa_in_synthesis.txt:
	@mkdir -p work
	$(JYTHON) taxa_in_synthesis.py \
	  $(SYNTH)/grafted_solution/grafted_solution.tre \
	  $@

clean:
	rm -f work/* trees_report.csv
