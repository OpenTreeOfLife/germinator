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

<!--
N.B. stats tables must use inline HTML, since web2py doesn't know how to render table markdown :-/
-->
<table class="table table-condensed">
 <tr>
  <th><!--statistic-->&nbsp;</th>
  <th>version5.0</th>
  <th>version6.1</th>
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
  <td>45397</td>
  <td>4171</td>
 </tr>
 <tr>
  <th>internal nodes in taxonomy</th>
  <td>127387</td>
  <td>127387</td>
  <td>0</td>
 </tr>
 <tr>
  <th>internal nodes from phylogeny</th>
  <td>37137</td>
  <td>40990</td>
  <td>3853</td>
 </tr>
 <tr>
  <th>broken taxa</th>
  <td>2400</td>
  <td>2653</td>
  <td>253</td>
 </tr>
 <tr>
  <th>subproblems</th>
  <td>5545</td>
  <td>5854</td>
  <td>309</td>
 </tr>
</table>

Note that the 'change' may not be a simple addition. For example, the number of subproblems in common between v5.0 and v6 is only 5240, meaning that both versions contain *unique* subproblems.
