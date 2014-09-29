Open Tree integration tests
=====

This repository holds integration tests, intended to answer the
question, is a new version of the web site good enough to go to
production?

Tests can be automated or manual.  Automated means you run a program
and the program does all the tests.  Manual means there are
human-readable instructions and a person runs them.  There should be a
low barrier to entry for adding tests, so if automation is really
hard, tests should be just listed for a person to do.

Unit tests live in particular applicable repositories.  See
TESTING.md in each repository for information about
repository-specific testing.

Tests are of two kinds: regression tests, and progress tests.

* Regression tests are tests that have passed in the past
* Progress tests are tests that we hope will pass one day

Here are manual tests we tend to do to kick the tires:

* Try the tree browser.
    * Go to the home page.  If the cellular orgnisms (or Asterales, etc.) tree is there, good.
    * Review the server information linked from the site footer. CONFIRM that we're using sensible URLs for all services.
    * Click on a node.  If you get a new tree view, great.
    * Try making a comment.
    * Try out an NCBI link (etc).
    * Try downloading a subtree.
    * Play with more of the tree browser UI.
    * Login and logout (by starting to add a comment).
    * Check the Bibliographic References page (touches a few services).

* Try curator app.
    * View a few studies: one in synthesis, one not in synthesis, one without a DOI.
    * Review the server information linked from the site footer. CONFIRM that we're using sensible URLs for all services, and esp. the appropriate docstore!
    * Click on a tree in the Trees list. You should see the tree in a popup, and a modified tree URL in the browser's address bar.
    * Check for sensible entries in its History tab.
    * Edit a study (also tests login and GitHub app).
    * Save (trivial) changes to a study.
    * Save more substantive changes to a (throwaway) study...
         * Map one or more OTUs (tests validation and taxon assignment)
         * Set ingroup clade
         * Update DOI or reference text via CrossRef.org lookup 
         * Test for tree MRCA
    * Confirm these changes in the main study list (tests save and "live" oti).

* Try the API.
    * Documentation [here](https://github.com/OpenTreeOfLife/opentree/wiki/Open-Tree-of-Life-APIs)
    * Do some of the curl calls
    * Mark H has a [script](http://phylo.bio.ku.edu/status/status.html).  A copy modified to point to devapi is [here](http://mumble.net/~jar/tmp/ot20-status.html).

* Taxon and relationship testing
    * Work in progress for smasher, taxomachine, and treemachine to check existence of taxa and relationships between them


Here are some things we don't do:

* Check for OTT-id-based URL stability across versions.
