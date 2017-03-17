# Building and deploying a new version of the synthetic tree

This is still a fairly manual process, although we aim to automate in the future
(possibly using ansible?).

Note: updating the taxonomy is a completely separate process, described [here](https://github.com/OpenTreeOfLife/germinator/wiki/Deploying-a-new-taxonomy-version).

**Overview**

The steps to build and deploy a new version of the synthetic tree are:

1. Build a new synthetic tree using
[propinquity](https://github.com/OpenTreeOfLife/propinquity) and create the tarballs for download.
* Load the synthetic tree into a neo4j database using code in [treemachine](https://github.com/OpenTreeOfLife/treemachine)
* Deploy the database to development (devapi) using scripts in
[germinator](https://github.com/OpenTreeOfLife/germinator).
* Manually create the release notes, update the synthesis statistics file, upload tarballs for download
* Update the conflict service to use the new synthetic tree
* Deploy to production

## Building the tree

Building the tree takes minimal resources, so you can do this locally or on a
server. Build the tree, extras and html docs using the pipeline in
[propinquity](https://github.com/OpenTreeOfLife/propinquity).
Specifically, the "[how the open tree of life synthetic tree is built](https://github.com/OpenTreeOfLife/propinquity#how-the-open-tree-of-life-synthetic-tree-is-built)"
section of the README describes the way that the propinquity tool was used
in synthesis version 5.0.
As of version 6.0,
the `[synthesis]` section of the config is:

    collections = josephwb/hypocreales kcranston/barnacles opentreeoflife/plants
    opentreeoflife/metazoa opentreeoflife/fungi opentreeoflife/safe-microbes
    opentreeoflife/default
    root_ott_id = 93302
    synth_id = opentree6.0

Increment the id by whole numbers, unless the change is trivial.

Create tarballs using the `bin/make_tarballs.sh` script. If you don't already
have all of the output in one directory, use the `bin/move_outputs.sh` script.  Use the `make_tarballs.sh` to create two archives:

* a small summary archive called `opentree{#}_tree.tgz`, with files:
  * `labelled_supertree/labelled_supertree.tre`
  * `labelled_supertree/labelled_supertree_ottnames.tre`
  * `grafted_solution/grafted_solution.tre`
  * `grafted_solution/grafted_solution_ottnames.tre`
  * `annotated_supertree/annotations.json`
  * a README file that describes the files
* a large archive called `opentree{#}_output.tgz` of all synthesis
  outputs, including `*.html` files

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

    tar -C {treemachine}/data/graph.db -czf treemachine-{20151104}.db.tgz .

This assumes that the graph database was built in the default location `graph.db`.
Replace `{20151104}` with the ISO 8601 (YYYYMMDD) date on which the database was generated (for identification purposes).

Then copy it to the server using rsync or scp, e.g:

    scp -p treemachine-{20151104}.db.tgz {host}:downloads/

where {host} is either the `devapi` or `api` server, depending on whether you
are testing or deploying.  Make sure there is adequate disk space before copying.

Next, use the `push.sh` script in the `deploy` directory of this repository (germinator) to unpack the database, make it available to neo4j, and restart the
neo4j service, as follows.  Again, before doing this, make sure there is adequate
disk space to unpack:

    ./push.sh -c {configfile} install-db downloads/treemachine-{20151104}.db.tgz treemachine

Check that the database is running with the correct version by calling the `tree_of_life/about` method:

    curl -X POST {host}/v3/tree_of_life/about -H "content-type:application/json" -d '{"include_source_list":false}'

## Updating the conflict service

Every time the conflict service starts up, it loads the synthetic tree
from the file `repo/reference-taxonomy/service/synth.tre` on the API
server.  Updating it consists simply of replacing this file and restarting the service.
The .tre file to use is
`labelled_supertree/labelled_supertree.tre`, although `labelled_supertree_ottnames.tre` would
also work.  Here is one way to proceed:

    ssh {host} mv repo/reference-taxonomy/service/synth.tre repo/reference-taxonomy/service/synth.tre.backup
    scp -pC labelled_supertree/labelled_supertree.tre {host}:repo/reference-taxonomy/service/synth.tre
    ./push.sh -c {configfile} smasher

The `-C` flag tells `scp` to compress the Newick string for transmission.

(If `labelled_supertree.tre` exists on the target server, then you
can create a symbolic link, to avoid making a second copy of it; but generally this isn't the case.)

Test the conflict service in the usual way (after waiting a minute or two for it to load):

    (cd reference-taxonomy/ws-tests; ./run_tests.sh host:apihost=https://{host})

Delete the backup file if everything seems to work:

    ssh {host} rm repo/reference-taxonomy/service/synth.tre.backup

## Updating web pages

The tree browser and bibliographic references pages will update automatically based on results from the api server. The following tasks need to be done manually:

**Release notes**

Create a file in `doc` (in the `germinator` repository) called
`ot-synthesis-v{#}.md`, where `#` is the synthesis version number e.g. `6.0`.
Edit this file, including links to the files for download and differences in
this version of the tree. Use the propinquity
[compare_synthesis_outputs.py](https://github.com/OpenTreeOfLife/propinquity/bin/compare_synthesis_outputs.py)
script to generate the comparison table for the release notes. Paste the table
into the release notes file under the heading '### Changes in output'. Once the
release notes file exists, the release will show up on the [releases
page](https://tree.opentreeoflife.org/about/synthesis-release/).

**Progress statistics**

Manually edit the [statistics
file](https://github.com/OpenTreeOfLife/opentree/blob/master/webapp/static/statistics/synthesis.json)
on a feature branch of the `opentree` repository, adding the following
statistics about the tree: `version`, `OTT_version`, `tree_count`,
`total_OTU_count`, and `tip_count`. These stats will then show up on the
[progress page](https://tree.opentreeoflife.org/about/progress). Merge the
feature branch to the `development` branch for testing devtree, and `master` for
production. Re-deploy the webapp as appropriate for the new statistics to show up
in the webapp.

**Files for downloads**

Create a version-specific subdirectory of the `files.opentreeoflife.org/synthesis` directory `opentree{#}` on the
`files.opentreeoflife.org` server. Then, copy the two tarballs there, e.g.:

    scp -p opentree6.0_*.tgz files.opentreeoflife.org:files.opentreeoflife.org/synthesis/opentree6.0/

Log in to `files.opentreeoflife.org` and extract the `opentree{#}_output.tgz`
file, creating an `output` directory.

Finally, *when you are ready to have the tree linked from the production system*, delete everything
in the `current` directory on `files.opentreeoflife.org`, and create
three symbolic links in this directory:

    cd synthesis/current
    rm -rf *
    ln -sf ../opentree{#}/opentree{#}_output.tgz current_output.tgz
    ln -sf ../opentree{#}/opentree{#}_tree.tgz current_tree.tgz
    ln -sf ../opentree{#}/output output

where `#` is the release number, e.g. `6.0`.
