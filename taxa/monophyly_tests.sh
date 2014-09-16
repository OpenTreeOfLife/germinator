#!/bin/bash

## Test special taxonomic nodes against the synthetic tree

echo -e "\nChecking status of: Glaucophyta..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":664970}'
echo -e "\nChecking status of: Bacteria..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":844192}'
echo -e "\nChecking status of: Chordata..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":125642}'
echo -e "\nChecking status of: Arachnida..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":511967}'
echo -e "\nChecking status of: Coleoptera..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":865243}'
echo -e "\nChecking status of: Archaea..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":996421}'
echo -e "\nChecking status of: Porifera..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":67819}'
echo -e "\nChecking status of: Fungi..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":352914}'
echo -e "\nChecking status of: Chloroplastida..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":361838}'
echo -e "\nChecking status of: Annelida..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":941620}'
echo -e "\nChecking status of: Eukaryota..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":304358}'
echo -e "\nChecking status of: Lepidoptera..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":965954}'
echo -e "\nChecking status of: Rhodophyta..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":878953}'
echo -e "\nChecking status of: Malacostraca..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":212701}'
echo -e "\nChecking status of: Arthropoda..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":632179}'
echo -e "\nChecking status of: Ctenophora..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":641212}'
echo -e "\nChecking status of: Cnidaria..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":641033}'
echo -e "\nChecking status of: Mollusca..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":802117}'
echo -e "\nChecking status of: Hymenoptera..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":753726}'
echo -e "\nChecking status of: Metazoa..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":691846}'
echo -e "\nChecking status of: Cunoniaceae..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":782239}'
echo -e "\nChecking status of: Haptophyta..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":151014}'
echo -e "\nChecking status of: Diptera..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":661378}'
