
# OpenTree Mendeley Group

There is an OpenTree Mendeley group containing papers whose associated
trees were recommended by group members for inclusion in Open Tree.

The Mendeley API is described [here](https://api.mendeley.com/apidocs).
The URL for retrieving the list of papers, as JSON, is

    https://api.mendeley.com:443/documents?group_id=673b01bd-2ff6-38e3-848c-540ab312f654&limit=400&order=asc&sort=created

Last time this was done, in December 2015, there were 710 papers.

My notes say there is a limit on how many papers on how many paper
blobs can be retrieved at once, so I did two calls, requesting 400
each time, one with `order=asc` and one with `order=desc`, in order to
get them all.

N.B. the the Mendeley API does support pagination for large result sets, as [documented here](http://dev.mendeley.com/reference/topics/pagination.html) and [demonstrated here](https://mendeleyapi.wordpress.com/2014/08/13/paginated-collections-an-example/). 

Before doing an API call you have to authenticate to Mendeley.  I
forget exactly how to do this, but you have to do one dummy HTTP
request providing an authentication header with username and password, and save the resulting cookie
to a file.  Then on the calls to the `documents` method, make sure
that the cookies get sent.  `wget` has everything you need for
saving and using cookies; I don't know about `curl`.

The result from December 2015 is here, in
[mendeley-papers.json](mendeley-papers.json).
