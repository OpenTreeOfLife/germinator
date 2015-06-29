This directory holds regression tests that can be used to check either
the taxonomy or the synthetic tree.

The files with names of the form monophyly*.csv have rows like the
following:

    Diptera,661378,"http://www.jstor.org/stable/2666712"

meaning:

"Raise an alert if the taxon _Diptera_ (as it is defined by OTT by ottid 661378) does not show up as
monophyletic.  Evidence for this monophyly claim may be found in
the article with DOI http://dx.doi.org/10.1006/mpev.2001.1055 ."

Similarly, the files inclusions*.csv have rows like the following:

    Taxon1,Taxon2,"remarks"

E.g.

    Odontomachus rixosus,Hymenoptera,788940,"http://dx.doi.org/10.1242/jeb.015263"

meaning:

"Raise an alert if the taxon _Odontomachus rixosus_ (with ottid 788940) does not show up as included in
the taxon Hymenoptera.  Evidence for this inclusion claim may be found
in the article with DOI http://dx.doi.org/10.1242/jeb.015263 ."

Or:

    Aeropyrum camini,Archaea,"http://www.ncbi.nlm.nih.gov/taxonomy accessed 2014-07-24"

"_Aeropyrum camini_ is in Archaea, according to
http://www.ncbi.nlm.nih.gov/taxonomy as it was when accessed on
2014-07-24."

"Inclusion" can be indirect, i.e. it doesn't refer to taxon
parent/child relationships but rather logical inclusion, as if the
taxa were sets of individual organisms or samples.

Remarks are free text.  Please make them as verbose as necessary in
order to help persuade a skeptic who doubts the claim at some unknown
future point in time.

Where there is any question, taxon names are as defined by OTT.  OTT
ids can be given in lieu of names, for truly difficult homonym
situations.  (For this to really work well the meaning of OTT ids has
to be anchored and stable. This is work in progress.)

The python script 'generate_test_scripts.py' will read the csv files 
"monophyly_tests.sh" and "inclusion_tests.sh" and generate shell scripts 
containing curl calls that will collect the desired data.

