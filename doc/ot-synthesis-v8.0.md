# Open Tree of Life version 8.0

Version 8.0 of the synthetic tree was generated on 29 November 2016 using the [propinquity pipeline](https://github.com/OpenTreeOfLife/propinquity).

## Downloads
There are two downloads. The first (smaller download) contain only tree and annotations files. The second (larger download) is the full output from the synthesis procedure, including documentation. You can also [browse the full output](http://files.opentreeoflife.org/synthesis/opentree8.0/output/index.html).

* [Tree and annotations](http://files.opentreeoflife.org/synthesis/opentree8.0/opentree8.0_tree.tgz) : Several versions of the synthetic tree, along with the annotations file. See the enclosed README for details. (compressed tar archive; 29 Mbytes)
* [All pipeline outputs](http://files.opentreeoflife.org/synthesis/opentree8.0/opentree8.0_output.tgz) : Outputs and documentation from all stages of the synthesis pipeline. Or, you can [browse the output](http://files.opentreeoflife.org/synthesis/opentree8.0/output/index.html) rather than downloading. (compressed tar archive; 151 Mbytes)

## Release notes

### Changes in inputs

* two new tree collections from a recent clade workshop at the Field Museum of Natural History ([Cnidaria](https://tree.opentreeoflife.org/curator/collections/pcart/cnidaria) and [Reef fishes](https://tree.opentreeoflife.org/curator/collections/mwestneat/reef-fishes))
* 99 new input trees, from the two new collections and from existing synthesis collections

### Changes in output

<!--
Get this table by running compare_synthesis_outputs.py in propinquity bin
dir. Stats tables must use inline HTML, since web2py doesn't know how to render table markdown :-/
-->
<table class="table table-condensed">
<tr>
<th><!--statistic-->&nbsp;</th>
<th>version7.0</th>
<th>version8.0</th>
<th>change</th>
<tr>
    <th>total tips</th>
    <td>2146904</td>
    <td>2131472</td>
    <td>-15432</td>
</tr>
<tr>
   <th>tips from phylogeny</th>
   <td>44608</td>
   <td>53012</td>
   <td>8404</td>
</tr>
<tr>
   <th>internal nodes from taxonomy</th>
   <td>191841</td>
   <td>191590</td>
   <td>-251</td>
</tr>
<tr>
   <th>internal nodes from phylogeny</th>
   <td>40482</td>
   <td>48448</td>
   <td>7966</td>
</tr>
<tr>
   <th>broken taxa</th>
   <td>2651</td>
   <td>3183</td>
   <td>532</td>
</tr>
<tr>
   <th>subproblems</th>
   <td>5907</td>
   <td>6712</td>
   <td>805</td>
</tr>
</table>
