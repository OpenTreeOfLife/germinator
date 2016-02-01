germinator
==============

The Open Tree system consists of a set of more or less
self-contained subsystems, each in its own repository.  These subsystems
get pulled together into an overall client/server web application, and
many of them can be used in other ways as well, either as standalone
utilities or as libraries.

The bits of glue that tie these modules together - documentation,
tests, initialization scripts, maintenance tasks - do not properly
belong in any of the subsystem repositories, so the 'germinator'
repository exists to give these things a home.

The starting point for Open Tree documentation is the 
[germinator wiki home page](https://github.com/OpenTreeOfLife/germinator/wiki).

Tests
-----

The germinator repo houses whole-system integration tests, including
an API test coordinator (see [TESTING.md](TESTING.md)) and lists of
taxa and taxon relationships for use in checking taxonomies and
synthetic trees (see [taxa/README.md](taxa/README.md)).

Statistics
----------

The files in the [statistics](statistics) directory contain manually
curated information about versions of the reference taxonomy and
synthetic tree.



Some very old scripts that aren't used any more
-----------------------------------------------

Currently, there are scripts for installing and setting up OTU and taxomachine.  They haven't been used in years.

Run scripts with the '--help' flag for information on options.

### setup_otu.sh

A simple script to help setup and test the otu client and associated neo4j database. To install OTU, run

    sh setup_otu.sh -prefix . --restart-neo4j --start-otu
    
Go to http://localhost:8000/ to use OTU.

Other options are:

```
setup_otu.sh <options>
  [--clean-db]
  [--test] (not yet)
  [--force]
  [--update-otu]
  [--recompile-plugin]
  [--restart-neo4j]
  [--start-otu]
  [--open-otu]
  [-prefix <path>]
```

### setup_taxomachine.sh

A simple script to help with installing taxomachine, building a taxonomy database, and running taxonomy services. To install taxomachine and build the a taxonomy database from the latest OTT release, run:

    setup_taxomachine.sh -prefix . --setup-db  --download-ott

Other options are:
```
setup_taxomachine.sh <options>
	[--clean-db]
	[--setup-db]
	[--download-ott]
	[--setup-server]
	[--restart-server]
	[--test]
	[--force]
	[--update-taxomachine]
	[--recompile-taxomachine]
	[--recompile-plugin]
	[-ott-version <2.0|2.1|2.2>]
	[-prefix <path>]
```


