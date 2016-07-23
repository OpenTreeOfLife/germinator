# Building and deploying a new version of the synthetic tree

**Overview**

The steps to build and deploy a new version of the synthetic tree are:

* build a new synthetic tree using  
[propinquity](https://github.com/OpenTreeOfLife/propinquity)
* load the synthetic tree into a neo4j database using code in [treemachine](https://github.com/OpenTreeOfLife/treemachine)
* deploy the database using scripts in
[germinator](https://github.com/OpenTreeOfLife/germinator)

## Building the tree

Building the tree takes minimal resources, so you can do this locally or on a
server. Build the tree and html docs using the pipeline in
[propinquity](https://github.com/OpenTreeOfLife/propinquity). As of version 6.0,
the `[synthesis]` section of the config is:

```
collections = josephwb/hypocreales kcranston/barnacles opentreeoflife/plants
opentreeoflife/metazoa opentreeoflife/fungi opentreeoflife/safe-microbes
opentreeoflife/default
root_ott_id = 93302
synth_id = opentree6.0
```

Increment the id by whole numbers, unless the change is trivial.

Assuming you have built the docs (`make html`, or by using one of the
run-everything scripts), create a tarball of the results. If the outputs are in
the top-level propinquity directory, there is a `move_outputs.sh` script in
`bin` that will move all of the output to a specified output directory.

## Loading the tree into neo4j

This step takes a large amount of memory, so you probably want to do this on a
server.  `varela.csail.mit.edu` is a good option.

Copy the following files to the machine you are using to build the
database:

* the synthetic tree: `labelled_supertree/labelled_supertree.tre`
* the tree annotations: `annotated_supertree/annotations.json`
* the taxonomy file used to build the tree: `taxonomy.tsv`

Follow the instructions for building treemachine, loading the tree into a neo4j
database, and running web service tests in the README for the [treemachine
repo](https://github.com/OpenTreeOfLife/treemachine).

## Deploying the database

Follow the instructions about [pushing a neo4j
database](https://github.com/OpenTreeOfLife/germinator/tree/master/deploy#how-to-push-a-neo4j-database)
in the [germinator repo](https://github.com/OpenTreeOfLife/germinator).

## To document

Stuff that still needs documentation

* where to put tarball of synthesis outputs
* how to update webapp (release page, version in URL)
* how to update statistics.json
* Bibliographic references page
