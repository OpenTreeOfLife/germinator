#!/bin/bash

## Test whether special taxonomic nodes are descendants of other special taxonomic nodes in the synthetic tree

echo -e "\nChecking inclusion of 'Pista wui' in 'Annelida'..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":105938, "include_lineage":true}'
echo -e "\nChecking inclusion of 'Rebecca salina' in 'Haptophyta'..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":168560, "include_lineage":true}'
echo -e "\nChecking inclusion of 'Synedra acus' in 'Eukaryota'..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":992764, "include_lineage":true}'
echo -e "\nChecking inclusion of 'Tuber indicum' in 'Fungi'..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":766380, "include_lineage":true}'
echo -e "\nChecking inclusion of 'Rhysida nuda' in 'Arthropoda'..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":849378, "include_lineage":true}'
echo -e "\nChecking inclusion of 'Car pini' in 'Coleoptera'..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":444291, "include_lineage":true}'
echo -e "\nChecking inclusion of 'Lima lima' in 'Mollusca'..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":124368, "include_lineage":true}'
echo -e "\nChecking inclusion of 'Lippia alba' in 'Chloroplastida'..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":603412, "include_lineage":true}'
echo -e "\nChecking inclusion of 'Acrotylus australis' in 'Rhodophyta'..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":637886, "include_lineage":true}'
echo -e "\nChecking inclusion of 'Malo kingi' in 'Cnidaria'..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":665121, "include_lineage":true}'
echo -e "\nChecking inclusion of 'Loa loa' in 'Metazoa'..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":555803, "include_lineage":true}'
echo -e "\nChecking inclusion of 'Bosea eneae' in 'Bacteria'..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":871815, "include_lineage":true}'
echo -e "\nChecking inclusion of 'Oscarella nicolae' in 'Porifera'..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":4939679, "include_lineage":true}'
echo -e "\nChecking inclusion of 'Pleurobrachia bachei' in 'Ctenophora'..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":742126, "include_lineage":true}'
echo -e "\nChecking inclusion of 'Ia io' in 'Chordata'..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":797470, "include_lineage":true}'
echo -e "\nChecking inclusion of 'Larca lata' in 'Arachnida'..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":895021, "include_lineage":true}'
echo -e "\nChecking inclusion of 'Uca osa' in 'Malacostraca'..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":357625, "include_lineage":true}'
echo -e "\nChecking inclusion of 'Osca lata' in 'Diptera'..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":4449665, "include_lineage":true}'
echo -e "\nChecking inclusion of 'Una usta' in 'Lepidoptera'..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":1082485, "include_lineage":true}'
echo -e "\nChecking inclusion of 'Odontomachus rixosus' in 'Hymenoptera'..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":788940, "include_lineage":true}'
echo -e "\nChecking inclusion of 'Cyanophora biloba' in 'Glaucophyta'..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":5401404, "include_lineage":true}'
echo -e "\nChecking inclusion of 'Aeropyrum camini' in 'Archaea'..."
curl -X POST http://devapi.opentreeoflife.org/v2/graph/node_info -H "content-type:application/json" -d '{"ott_id":28783, "include_lineage":true}'
