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

These instructions are based on [pushing a neo4j
database](https://github.com/OpenTreeOfLife/germinator/tree/master/deploy#how-to-push-a-neo4j-database)
in `deploy/README.md`. See that file for instructions on setting up a server and managing credentials. Test the database on the development server, `devapi`, before pushing to production.

Create a compressed tar file of the neo4j database directory:

    tar -C {txxxmachine}/data/newlocaldb.db -czf newlocaldb.db.tgz .

Then copy it to the server using rsync or scp, e.g:

    scp -p newlocaldb.db.tgz {host}:downloads/treemachine-{20151104}.db.tgz

where {host} is either the `devapi` or `api` server, depending on whether you
are testing or deploying; and and {20151104} is date on which the database was
generated (for identification purposes). Make sure there is adequate disk space before copying.

Next, use the `push.sh` script in the `deploy` directory to unpack the database, make it available to neo4j, and restart the
neo4j service.  Again, before doing this, make sure there is adequate
disk space.

    ./push.sh -c {configfile} install-db downloads/treemachine-{20151104}.db.tgz treemachine

Check that the database is running with the correct version by calling the `tree_of_life/about` method:

    curl -X POST {host}/v3/tree_of_life/about -H "content-type:application/json" -d '{"include_source_list":false}'

## Updating web pages

The tree browser and bibliographic references pages will update automatically based on results from the api server. The following tasks need to be done manually:

**Files for downloads**

Using propinquity output, create two tarballs for inclusion on the release page:

* a small summary archive called `opentree{#}_tree.tgz`, containing these files:
  * `labelled_supertree/labelled_supertree.tre`
  * `labelled_supertree/labelled_supertree_ottnames.tre`
  * `grafted_solution/grafted_solution.tre`
  * `grafted_solution/grafted_solution_ottnames.tre`
  * `annotated_supertree/annotations.json`
  * a README.html file that describes the files
* a large archive called `opentree{#}_output.tgz` of all synthesis outputs, including `*.html` files

Create a version-specific subdirectory of the `synthesis` directory on `files.opentreeoflife.org` server. Then, copy these files there, e.g.:

    scp -p opentree6.0_*.tgz files.opentreeoflife.org:synthesis/opentree6.0/

Log into `files.opentreeoflife.org` and extract the `opentree{#}_output.tgz` file
Finally, delete the contents of the `current` directory on `files.opentreeoflife.org` and create three symbolic links in this directory:

    cd synthesis
    ln current/current_output.tgz opentree{#}/opentree{#}_output.tgz
    ln current/current_tree.tgz opentree{#}/opentree{#}_tree.tgz
    ln current/output opentree{#}/output

Where `#` is the release number, e.g. `6.0`.

**Release notes**

Create a file in `doc` called  `ot-synthesis-v{#}.md` where `#` is an integer version number. Edit this file, including links to the files for download and differences in this version of the tree. At this point, we are creating these notes manually, but plan to automate this in the future, likely some code from the propinquity `compare_synthesis_outputs.py`  script. Once the release notes file exists, the release will show up on the [releases page](https://tree.opentreeoflife.org/about/synthesis-release/).

**Progress statistics**

Manually edit the [statistics file](https://github.com/OpenTreeOfLife/opentree/blob/master/webapp/static/statistics/synthesis.json) with the following statistics about the tree: version, OTT_version, tree_count, total, and tip_count. These stats will then show up on the [progress page](https://tree.opentreeoflife.org/about/progress).
