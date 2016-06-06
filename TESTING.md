# Open Tree integration tests

This repository holds integration tests, intended to answer the
question, is a new version of the web site good enough to go to
production?

### Web service (API) testing

Tests for the Open Tree APIs reside in the ws-tests directories of the
respective repositories (phylesystem-api, treemachine, taxomachine,
oti, and reference-taxonomy).

One can run all tests, tests for a single API component, or individual
tests.

To run all tests for all components:

    cd germinator
    ws-tests/run_tests.sh https://devapi.opentreeoflife.org

substituting the actual name of the API server you'd like to test.
(You can also run it from the germinator/ws-tests directory if you prefer.)

Some setup is required for the run_test.sh script.  It assumes there
are clones of all five component repositories, and that all the
repository clones are siblings (i.e. all are subdirectories of a
common directory).  If this is not the case, you'll have to
create symbolic links in germinator's parent simulating this situation:

    cd germinator/..
    ln -s {location of phylesystem-api repo clone} taxomachine
    ln -s {location of oti repo clone} oti
    # etc. for all five API component repositories

A few of the phylesystem-api tests require that peyotl be installed.
If it isn't, they will just fail, which is distracting but OK.

Individual API components (OTI, etc.) can be tested either using the
`-t` flag, or by running `run_tests.sh` from the appropriate ws-tests
directory.  The argument to `-t` is the ws-tests directory for the
component in question, e.g.

    ../germinator/ws-tests/run_tests.sh -t . https://devapi.opentreeoflife.org

or

    ../germinator/ws-tests/run_tests.sh -t ../oti/ws-tests https://devapi.opentreeoflife.org

It is also possible to run individual tests (\*/ws-tests/test_\*.py).
These require the `opentreetesting` module, so
PYTHONPATH has to contain the `germinator/ws-tests` directory.
To set the API 
URL you have to say `host:apihost=URL` instead of just URL.
See [the phylesystem-api documentation](https://github.com/OpenTreeOfLife/phylesystem-api/blob/master/TESTING.md).
E.g.

    cd oti/ws-tests
    export PYTHONPATH=$PWD/../../germinator/ws-tests:$PYTHONPATH
    python test-basic.py host:apihost=https://devapi.opentreeoflife.org

There are optional configuration directives for the tests.  These can
be set either from a configuration file or on the command line using
the syntax section:parameter=value.  See [the phylesystem-api
documentation](https://github.com/OpenTreeOfLife/phylesystem-api/blob/master/ws-tests/README.md)
for instructions.

### Taxonomy and phylogeny testing

Lists of inclusion and monophyly tests are in the taxa/ directory.
They can be run against either the taxonomy or the synthetic tree.
Scripts for doing so may be found in the respective repositories.

There are some progress tests (see below) in these lists.  They are not currently
marked as such except in comments, so expect a few failures.  This should be fixed.

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
