# Report various information on all trees in phylesystem

'make' creates trees_report.csv, which has the following columns:

 * tree - identifier for the tree in studyid@treeid form
 * intended - 0 if study not intended for synthesis, 2 if intended, 1 if not specified
 * preferred - 2 if preferred tree or only tree, 1 if no tree is preferred, 0 if not preferred
 * has ingroup - 1 if has designated ingroup, 0 otherwise
 * has method - 1 if there's something in the 'curated type' field, 0 otherwise
 * #mapped - number of taxa (in OTT) to which tips are mapped
 * #tips - total number of tips in tree
 * #conflicts - number of nodes in synthetic tree that conflict with tree nodes
 * #resolved - number of nodes in tree that resolve synthetic tree nodes
 * #new - number of taxa from tree that aren't already in synthetic tree

The table is generated with a particular heuristic sort order, but may
be re-sorted at will in your favorite spreadsheet program.

Smasher is used for conflict analysis and for parsing the Newick file
for the synthetic tree without taxonomy.  The results are placed in
work/conflict.csv and work/synthesis_tree_list.csv.

## Configuration

 * Assuming this directory is `trees_report` in some repo, say G, the parent directory of 
   G should contain the following either as directories or as symbolic links:
     * reference_taxonomy
     * peyotl
     * collections-1
     * phylesystem-1
 * Install peyotl
 * Go to the reference-taxonomy repo and say `make compile bin/jython` (as of 2016-05-09, 
   the `cleanups-for-writeup` branch of the reference-taxonomy repo is required, but
   I expect this to get merged to master in the near future)
 * Adjust SYNTH in the Makefile or put synthesis files in that location.  It 
   needs the files `output/labelled_supertree/labelled_supertree.tre` and
   `output/grafted_solution/grafted_solution.tre`
 * dot_peyotl is the peyotl configuration file, but it should require

## Known issues

 * Does not processes the forwards.tsv file from OTT, meaning many
   taxa from trees will appear new that aren't
 * Does not know anything about incertae sedis (unplaced etc.), again making taxa 
   appear new that cannot go into synthesis
