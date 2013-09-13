otbootstrap
==============

Scripts for setting up databases and performing common tasks.

Eventually, the hope is that these tools can be leveraged to automate spawning of new database instances for curation, development, and general use.

Currently, there are scripts for installing and setting up OTU and taxomachine.

Run scripts with the '--help' flag for information on options.

setup_otu.sh
------------

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

setup_taxomachine.sh
------------

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


