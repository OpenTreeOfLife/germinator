Open Tree integration tests
=====

(STUB, PLEASE ADD ITEMS)

We badly need some tests.

Mainly integration tests - is the site good enough to go to production?

But unit tests would be nice too.  They would live in particular repos
and might be invoked from here.

Tests can be automated or manual.  Automated means you run a program
and the program does all the tests.  Manual means there are
human-readable instructions and a person runs them.  There should be a
low barrier to entry for adding tests, so if automation is really
hard, tests should be just listed for a person to do.

Tests are of two kinds: regression tests, and progress tests.

* Regression tests are tests that have passed in the past
* Progress tests are tests that we hope will pass one day

There are no formal tests now.  Here are things we tend to do to kick
the tires: (INCOMPLETE, PLEASE EXTEND)

* Try the browser.
    * Go to the home page.  If the cellular orgnisms (or Asterales, etc.) tree is there, good.
    * Review the server information linked from the site footer. CONFIRM that we're using sensible URLs for all services.
    * Click on a node.  If you get a new tree view, great.
    * Try out an NCBI link (etc).
    * Try downloading a subtree.
    * Play with more of the tree browser UI.
    * Login and logout (by starting to add a comment).

* Try curator app.
    * View a study.
    * Review the server information linked from the site footer. CONFIRM that we're using sensible URLs for all services, and esp. the appropriate docstore!
    * Click on a node.  If you get a new tree view, great.
    * Check for sensible entries in its History tab.
    * Edit a study (also tests login and GitHub app).
    * Save (trivial) changes to a study.
    * Confirm these changes in the main study list (tests save and "live" oti).

* Try the API.
    * Do some of the curl calls (phylesystem, oti, taxo, tree).  Mark has a script.

Here are some things we don't do:

* Check for OTT-id-based URL stability across versions.
