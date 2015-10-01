# Open Tree integration tests

This repository holds integration tests, intended to answer the
question, is a new version of the web site good enough to go to
production?

### Theory of tests

Tests can be automated or manual.  Automated means you run a program
and the program does all the tests.  Manual means there are
human-readable instructions and a person runs them.  There should be a
low barrier to entry for adding tests, so if automation is really
difficult, tests should be just listed for a person to do.

A test can be a unit test or an integration test.
Unit tests live in particular applicable repositories.  See
TESTING.md in each repository for information about
repository-specific testing.

Tests are of two kinds: regression tests, and progress tests.

* Regression tests are tests that have passed in the past
* Progress tests are tests that we hope will pass one day, but don't currently

### Web service (API) testing (old method) 

Use the test.sh script, in the root level directory of the repository.
It takes one command line argument, the name of the api server to be tested.

### Web service (API) testing (new method, work in progress) 

Tests for particular components of the API reside in the ws-tests of
the respective repositories.

To run all tests for all components:

    cd ws-tests
    run_tests.sh devapi.opentreeoflife.org

substituting the actual name of the API server you'd like to test.

Individual API components (OTI, etc.) can be tested using run_tests.sh
(the one defined in the phylesystem-api repository, not the one defined
here).  It is also possible to run individual ws-tests/test_*.py files.  See 
[the documentation](https://github.com/OpenTreeOfLife/phylesystem-api/blob/master/TESTING.md).
You will need

    export PYTHONPATH={path to phylesystem-api repo}/ws-tests

* API documentation [here](https://github.com/OpenTreeOfLife/opentree/wiki/Open-Tree-of-Life-APIs)
* Mark H has a [script](http://phylo.bio.ku.edu/status/status.html).

### Taxonomy and phylogeny testing 

Lists of inclusion and monophyly tests are in the taxa/ directory.
They can be run against either the taxonomy or the synthetic tree.
Scripts for doing so may be found in the respective repositories.

There are some progress tests in these lists.  They are not currently
marked as such except in comments, so expect a few failures.

### Testing the overall open tree application 

Here are some manual tests we sometimes do to kick the tires:

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

### Deployed system operation checks 

We run a nagios process on a server (varela.csail.mit.edu), which
sends email to a short list of people if the application fails to
respond properly to various kinds of HTTP requests.

