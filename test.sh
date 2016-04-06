# Try out some v3 API methods

set -e

failures=0
successes=0

apihost=$1
if [ x$apihost = x ]; then
    echo "No api host specified"
    exit 1
fi

baseurl=$apihost
if [ "${baseurl:0:4}" != "http" ]; then
    baseurl="https://$baseurl"
fi

function simple_curl_test {
    method="$1"
    args="$2"
    checkfor="$3"
    if curl --silent -X POST "$baseurl/v3/$method" -H "content-type:application/json" -d "$args" > curl.out; then
	if grep -q "$checkfor" curl.out; then
	    successes=$((successes + 1))
	else
	    echo "*** Failed:" $method $args $checkfor
	    cat curl.out
	    echo
	    failures=$((failures + 1))
	fi
    else
        echo "*** Curl failed:" $method $args $checkfor
	cat curl.out
	echo
	failures=$((failures + 1))
    fi
}

simple_curl_test tree_of_life/about '{"study_list":false}' num_source_studies

# 901642 = Alseuosmia banksii
# 55033 = Wittsteinia panderi
# 637370 = Alseuosmiaceae (in Asterales)
simple_curl_test tree_of_life/mrca '{"ott_ids":[901642, 55033]}' 637370

simple_curl_test tree_of_life/subtree '{"ott_id":876342}' "Alseuosmia_macrophylla"

simple_curl_test tree_of_life/induced_subtree '{"ott_ids":[901642, 55033]}' "Wittsteinia_panderi"

# Requires commit sha, which is hard to get
if false; then
    simple_curl_test graph/source_tree '{"study_id":"pg_41", "tree_id":"1396", "git_sha":"07054f960e6a5d42660af2bdda2fcc0a26120d71"}' "Lechenaultia_hirsuta"
fi

# Pegolettia senegalensis = 782981
simple_curl_test tree_of_life/node_info '{"ott_id":782981}' "gbif:3139179"

simple_curl_test tnrs/match_names '{"names":["Aster","Symphyotrichum","Erigeron"]}' "643717"

simple_curl_test taxonomy/mrca '{"ott_ids":[901642, 55033]}' 637370

simple_curl_test taxonomy/taxon_info '{"ott_id":901642}' "Alseuosmia banksii"

simple_curl_test studies/find_studies '{"property":"ot:studyId","value":"pg_41","verbose":true}' "Cariaga"


echo Successes: $successes Failures: $failures
exit $failures
