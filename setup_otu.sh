# download the tarball
wget https://www.dropbox.com/s/pmwaid6i1sz3cyp/otu.test.tar.gz

# extract and cd into the new dir
tar -xvf otu.test.tar.gz
cd otu

# start the neo4j that comes with this
# note: cannot have other running neo4j instances or this will fail
./neo4j-community-1.9.2/bin/neo4j start

# start the webserver (from the views directory -- this is important for redirects)
cd views

# open the tool in the web browser
xdg-open http://localhost:8000/

# start the server
./server.py
	
