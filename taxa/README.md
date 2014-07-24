The file inclusions.csv has rows like the following:

    Taxon1,Taxon2,"remarks"

E.g.

    Odontomachus rixosus,Hymenoptera,"http://dx.doi.org/10.1242/jeb.015263"

meaning:

"Raise an alert if the taxon _Odontomachus rixosus_ is not included in
the taxon Hymenoptera.  Evidence for this inclusion claim may be found
in the article with DOI http://dx.doi.org/10.1242/jeb.015263 ."

Or:

    Aeropyrum camini,Archaea,"http://www.ncbi.nlm.nih.gov/taxonomy accessed 2014-07-24"

"_Aeropyrum camini_ is in Archaea, according to
http://www.ncbi.nlm.nih.gov/taxonomy as it was when accessed on
2014-07-24."

Remarks are free text.  Please make them as verbose as necessary in
order to help persuade a skeptic who doubts the claim at some unknown
future point in time.

Similarly monophyly.csv

    Archaea,"http://www.ncbi.nlm.nih.gov/taxonomy accessed 2014-07-24"

Where there is any question, taxon names are as defined by OTT.  OTT
ids can be given in lieu of names, for truly difficult situations.
(For this to work the meaning of OTT ids has to be anchored. This is
work in progress.)
