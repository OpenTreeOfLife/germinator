# Treemachine-associated scripts

## `fetch_arguson.py`
This script is currently not used in our infrastructure or deployment.
It was written to get a sense of whether it might be feasible to cache
    the getSyntheticTree responses for all nodes in the synthetic tree
That is the method that the web-app uses to crawl over the tree.
If we could cache the responses, then the basic browsing of the tree would still
    work even the server experienced heavy load.
The autocompleteQuery used for searching for a taxon might still be vulnerable to heavy
    load.

Before deploying we'd want to set the SLEEP_INTERVAL variable to a small #.
If we wanted to parallelize the creation of the cache on differnt machines, we'd need
to revise the strategy of just recursing.

Inital results look promising in terms of space: with each response gzipped, it looks
    like all of the node will require approximately 20G of storage

**Dependencies:** python with the requests python package.

You have to know the root node ID (132 synthesis 2 deployed in Sept 2014). So:

    $ python fetch_arguson.py 132

would fetch the root node and:

    $ python fetch_arguson.py -r2 132

would fetch it, its children, and their children.