# Open Tree of Life version 7.0

Version 7.0 of the synthetic tree was generated on 11 September 2016 using the [propinquity pipeline](https://github.com/OpenTreeOfLife/propinquity).

## Downloads
There are two downloads. The first (smaller download) contain only tree and annotations files. The second (larger download) is the full output from the synthesis procedure, including documentation. You can also [browse the full output](http://files.opentreeoflife.org/synthesis/opentree7.0/output/index.html).

* [Tree and annotations](http://files.opentreeoflife.org/synthesis/opentree7.0/opentree7.0_tree.tgz) : Several versions of the synthetic tree, along with the annotations file. See the enclosed README for details. (compressed tar archive; 49 Mbytes)
* [All pipeline outputs](http://files.opentreeoflife.org/synthesis/opentree7.0/opentree7.0_output.tgz) : Outputs and documentation from all stages of the synthesis pipeline. Or, you can [browse the output](http://files.opentreeoflife.org/synthesis/opentree7.0/output/index.html) rather than downloading. (compressed tar archive; 128 Mbytes)

## Release notes

### Changes in inputs

* New taxonomy version, now now ott2.10. Major changes are new NCBI version and removal of taxa marked invalid in IRMNG. See [OTT release notes](https://tree.opentreeoflife.org/about/taxonomy-version/ott2.10) for details.
* Three new input trees:  [Herrera, 2016](https://tree.opentreeoflife.org/curator/study/view/ot_722?tab=trees&tree=tree1), [Toussaint, 2016](https://tree.opentreeoflife.org/curator/study/view/ot_764?tab=trees&tree=tree1), [Malmstrøm, 2016](https://tree.opentreeoflife.org/curator/study/view/ot_771?tab=trees&tree=tree1)

### Changes in output

Note that the reduction in nodes is largely due to the removal of taxa marked invalid in IRMNG.

<!--
N.B. stats tables must use inline HTML, since web2py doesn't know how to render table markdown :-/
-->
<table class="table table-condensed">
 <tr>
  <th><!--statistic-->&nbsp;</th>
  <th>version6.1</th>
  <th>version7.0</th>
  <th>change</th>
 </tr>
 <tr>
  <th>total tips</th>
  <td>2424255</td>
  <td>2146904</td>
  <td>-277351</td>
 </tr>
 <tr>
  <th>tips from phylogeny</th>
  <td>45397</td>
  <td>44608</td>
  <td>-789</td>
 </tr>
 <tr>
  <th>internal nodes in taxonomy</th>
  <td>127387</td>
  <td>127387</td>
  <td>0</td>
 </tr>
 <tr>
  <th>internal nodes from phylogeny</th>
  <td>40990</td>
  <td>40482</td>
  <td>-508</td>
 </tr>
 <tr>
  <th>broken taxa</th>
  <td>2653</td>
  <td>2651</td>
  <td>-2</td>
 </tr>
 <tr>
  <th>subproblems</th>
  <td>5545</td>
  <td>5854</td>
  <td>309</td>
 </tr>
</table>

Note that the 'change' may not be a simple addition. For example, the number of subproblems in common between v5.0 and v6 is only 5240, meaning that both versions contain *unique* subproblems.
