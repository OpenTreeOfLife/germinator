# Open Tree of Life synthetic tree version 6.0

Version 6.0 of the synthetic tree was generated on 22 July 2016 using the [propinquity pipeline](https://github.com/OpenTreeOfLife/propinquity).

## Downloads
There are two downloads. The first (smaller download) is the tree and annotations file only. The second (larger download) is the full output from the synthesis procedure, including documentation. You can also browse the full output.

* [Synthetic tree](http://files.opentreeoflife.org/synthesis/opentree6.0/opentree6.0_tree.tar.gz) : includes the full tree, annotations file, and a phylo-only tree (tips only from taxonomy pruned off). See the enclosed README for details. (compressed tar archive; 32 Mbytes)
* [All pipeline outputs](http://files.opentreeoflife.org/synthesis/opentree6.0/opentree5.0_output.tgz) : Outputs and documentation from all stages of the synthesis pipeline. Or, you can [browse the output](http://files.opentreeoflife.org/synthesis/opentree6.0/output/index.html) rather than downloading. (compressed tar archive; 138 Mbytes)

## Release notes

The major change in this version is the inclusion of 155 new phylogenies from the data store. This increases resolution of the tree, but also contradicts a larger number of named taxa.

### Changes in inputs

* two additional tree collections, [josephwb/hypocreales](https://tree.opentreeoflife.org/curator/collections/josephwb/hypocreales) and [opentreeoflife/default](https://tree.opentreeoflife.org/curator/collections/opentreeoflife/default)
* which add 155 new phylogenetic trees (677 trees total included)

### Changes in output

<!-- 
N.B. stats tables must use inline HTML, since web2py doesn't know how to render table markdown :-/ 
-->
<table class="table table-condensed">
 <tr>
  <th><!--statistic-->&nbsp;</th>
  <th>version5</th>
  <th>version6</th>
  <th>change</th>
 </tr>
 <tr>
  <th>total tips</th>
  <td>2424255</td>
  <td>2424255</td>
  <td>0</td>
 </tr>
 <tr>
  <th>tips from phylogeny</th>
  <td>41226</td>
  <td>45406</td>
  <td>4180</td>
 </tr>
 <tr>
  <th>internal nodes</th>
  <td>235099</td>
  <td>238398</td>
  <td>3299</td>
 </tr>
 <tr>
  <th>broken taxa</th>
  <td>2400</td>
  <td>2646</td>
  <td>206</td>
 </tr>
 <tr>
  <th>subproblems</th>
  <td>5545</td>
  <td>5858</td>
  <td>313</td>
 </tr>
</table>

Note that the 'change' may not be a simple addition. For example, the number of subproblems in common between v5.0 and v6 is only 5240, meaning that both versions contain *unique* subproblems.
