# Overview


The germinator project now includes scripts that generate json-format statistics for phylesystem instances and for synthetic trees.

## Report generation scripts


### phylesystem_stats.py  
### synthesis_stats.py


## Report 'push' scripts
These scripts use rrsync to push the output of the generation scripts to the
appropriate location in a web2py application running on a server machine.

##Report Formats


### Fields for phylesystem reports

* study_count 
* unique\_OTU\_count
* OTU_count
* reported\_study\_count - integer length of list of studies returned
* nominated\_study\_count
* nominated\_study\_OTU\_count
* nominated\_study\_unique\_OTU_count
* run_time - elapsed time for processing, including queries


### Fields for synthesis reports

* reported\_study\_count - integer length of list of studies returned
* study_count - integer number of studies that returned otus when queried
* total\_OTU\_count - integer length of list of all OTUs retrieved by study queries
* unique\_OTU\_count - integer length of list without duplicates
* run_time - elapsed time for processing, including queries

