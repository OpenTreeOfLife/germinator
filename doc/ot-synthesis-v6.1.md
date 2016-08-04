# Open Tree of Life synthetic tree version 6.1

Version 6.1 of the synthetic tree was generated on 2 August 2016 using the [propinquity pipeline](https://github.com/OpenTreeOfLife/propinquity).

## Downloads
There are two downloads. The first (smaller download) contain only tree and annotations files. The second (larger download) is the full output from the synthesis procedure, including documentation. You can also [browse the full output](http://files.opentreeoflife.org/synthesis/opentree6.1/output/index.html).

* [Tree and annotations](http://files.opentreeoflife.org/synthesis/opentree6.1/opentree6.1_tree.tar.gz) : Several versions of the synthetic tree, along with the annotations file. See the enclosed README for details. (compressed tar archive; 32 Mbytes)
* [All pipeline outputs](http://files.opentreeoflife.org/synthesis/opentree6.1/opentree6.1_output.tgz) : Outputs and documentation from all stages of the synthesis pipeline. Or, you can [browse the output](http://files.opentreeoflife.org/synthesis/opentree6.1/output/index.html) rather than downloading. (compressed tar archive; 138 Mbytes)

## Release notes

The major change between version6.1 and version5.0 is the inclusion of 155 new phylogenies from the data store. This gives 4173 more tips covered by phylogeny, increases resolution of the tree, and contradicts a larger number of named taxa.

### Changes in inputs

* two additional tree collections, [josephwb/hypocreales](https://tree.opentreeoflife.org/curator/collections/josephwb/hypocreales) and [opentreeoflife/default](https://tree.opentreeoflife.org/curator/collections/opentreeoflife/default)
* 155 new phylogenetic trees (677 trees total included)

### Changes in output

| statistic | version5 | version6 | change |
| --------- | -------- | -------- | ------ |
| total tips | 2424255 | 2424255 | 0 |
| tips from phylogeny | 41226 | 45397 | 4173 |
| forking nodes in grafted tree |  37137 |  40990 | 3853 |
| forking nodes in taxonomy |  127387 | 127387 | 0 |
| broken taxa | 2400 | 2653 | 253 |
| subproblems | 5545 | 5854 | 309 |

Note that the 'change' may not be a simple addition. For example, the number of subproblems in common between v5.0 and v6 is only 5240, meaning that both versions contain *unique* subproblems.
