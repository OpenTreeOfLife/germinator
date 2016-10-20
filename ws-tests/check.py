# Common type checking logic and types to be used by all tests
# Copied from treemachine/ws-tests/  - eventually remove that

import sys, json
import traceback
from opentreetesting import test_http_json_method
from opentreetesting import config

# Returns 1 for failure, 0 for success

def simple_test(path, input, check=None, expected_status=200, is_right=(lambda x:True)):
    DOMAIN = config('host', 'apihost')
    url = DOMAIN + path
    try:
        # print 'checking', url
        (win, output) = test_http_json_method(url, verb='POST', data=input,
                                              expected_status=expected_status,
                                              return_bool_data=True)
        if not win:
            # Error message already printed
            print '** http lose'
            return 1
        if isinstance(output, dict) and 'error' in output:
            # Should be 400, not 200
            print '** error', output
            return 1
        elif check == None:
            return 0
        elif check(output, ''):
            if is_right(output):
                return 0
            else:
                print '** result is not right', output
                return 1
        else:
            return 1
    except Exception, e:
        print '** exception', e
        traceback.print_exc()
        return 1

def check_integer(x, where):
    if isinstance(x, int) or isinstance(x, long):
        return True
    else:
        print '** expected integer but got', x, where
        return False

def check_float(x, where):
    if isinstance(x, float):
        return True
    else:
        print '** expected float but got', x, where
        return False

def check_string(x, where):
    if isinstance(x, unicode):
        return True
    else:
        print '** expected string but got', x, where
        return False

def check_boolean(x, where):
    if x == True or x == False:
        return True
    else:
        print '** expected boolean but got', x, where
        return False

def check_source_id(x, where):
    if not isinstance(x, unicode):
        print '** expected string (source id) but got', x, where
        return False
    elif '.' in x:
        # taxonomy id is ott2.9draft7 or similar.
        return True
    elif '@' in x:
        # source tree id is pg_123@tree456 or similar.
        return True
    else:
        print '** expected a source id but got', x, where
        return False

# XML id for a node in a source tree
def check_sourcenode_id(x, where):
    if not isinstance(x, unicode):
        print '** expected string (source id) but got', x, where
        return False
    elif len(x) == 0:
        print '** expected non-null source node id but got null', where
        return False
    elif x.startswith(u'ott'):
        print '** suspicious source node id', x, where
        return False
    else:
        return True

# In v3, the unique_name should never be null
def check_unique_name(x, where):
    if not isinstance(x, unicode):
        print '** expected string but got', x, where
        return False
    elif len(x) == 0:
        print '** expected non-null unique_name but got null', where
        return False
    else:
        return True

def check_rank(x, where):
    if not isinstance(x, unicode):
        print '** expected string but got', x, where
        return False
    elif len(x) == 0:
        print '** expected non-null rank but got null', where
        return False
    else:
        return True


def field(name, check):
    if not isinstance(check, type(check_integer)):
        print '** bad check function', check, 'for', name
        return (name, (lambda x, where: False), True)
    return (name, check, True)

def opt_field(name, check):
    return (name, check, False)

def check_blob(fields):
    required = [name for (name, check, req) in fields if req]
    checks = {}
    for (name, check, req) in fields:
        checks[name] = check
    def do_check_blob(x, where):
        if not isinstance(x, dict):
            print '** expected dict but got', x, where
            return False
        win = True
        for name in x:
            if name in checks:
                check = checks[name]
                if not check(x[name], more_where(name, where)):
                    win = False
            else:
                print "** unexpected field '%s' found among %s %s" % (name, x.keys(), where)
                win = False
        for name in required:
            if not (name in x):
                print "** missing required field '%s' not found among %s %s" % (name, x.keys(), where)
                win = False
        return win
    return do_check_blob

def check_list(check):
    def do_check_list(x, where):
        if not isinstance(x, list):
            print '** expected list but got', x, where
            return False
        where = more_where('list', where)
        for y in x:
            if not check(y, where):
                return False
        return True
    return do_check_list

def check_nonempty_list(check):
    ch = check_list(check)
    def do_check_nonempty_list(x, where):
        if x == []:
            print '** expected nonempty list but got', x, where
            return False
        else:
            return ch(x, where)
    return do_check_nonempty_list

def more_where(w, where):
    if where == '':
        return where
    else:
        return w + ' in ' + where

# Check types of all keys and values in a dictionary

def check_dict(check_key, check_val):
    def do_check_dict(x, where):
        if not isinstance(x, dict):
            print '** expected dict but got', x, where
            return False
        ok = True
        for key in x:
            if not check_key(key, where):
                ok = False
            val = x[key]
            if not check_val(val, ' in ' + key + where):
                ok = False
        return ok
    return do_check_dict

taxon_blob_fields = [field(u'ott_id', check_integer),
                     field(u'name', check_string),
                     field(u'rank', check_rank),
                     field(u'unique_name', check_unique_name),
                     field(u'tax_sources', check_list(check_string))]

check_taxon_blob = check_blob(taxon_blob_fields)

# treemachine only
check_single_support_blob = check_dict(check_source_id, check_string)

check_multi_support_blob = check_dict(check_source_id, check_nonempty_list(check_string))

node_blob_fields = [field(u'node_id', check_string),
                    opt_field(u'taxon', check_taxon_blob),
                    field(u'num_tips', check_integer),
                    opt_field(u'supported_by', check_single_support_blob),
                    opt_field(u'resolves', check_single_support_blob),
                    opt_field(u'resolved_by', check_multi_support_blob),
                    opt_field(u'conflicts_with', check_multi_support_blob),
                    opt_field(u'partial_path_of', check_single_support_blob),
                    opt_field(u'terminal', check_single_support_blob),
                    opt_field(u'was_constrained', check_boolean),
                    opt_field(u'was_uncontested', check_boolean)]

check_node_blob = check_blob(node_blob_fields)

check_source_tree_blob = check_blob([field(u'git_sha', check_string),
                                     field(u'tree_id', check_string),
                                     field(u'study_id', check_string)])

check_taxonomy_blob = check_blob([field(u'taxonomy', check_string),
                                  opt_field(u'version', check_string),
                                  opt_field(u'name', check_string)])

# dictionary describing one source, either a source tree or a taxonomy

def check_source_blob(x, where):
    if isinstance(x, dict) and u'tree_id' in x:
        return check_source_tree_blob(x, where)
    else:
        return check_taxonomy_blob(x, where)

check_source_id_map = check_dict(check_source_id, check_source_blob)

# check_arguson_blob is recursive, so need to eta-convert to deal with circularity
def check_arguson_blob(x, where):
    return really_check_arguson_blob(x, where)

lineage_blob_fields = (node_blob_fields +
                       [opt_field(u'descendant_name_list', check_list(check_string))])

check_lineage_blob = check_blob(lineage_blob_fields)

arguson_blob_fields = (lineage_blob_fields +
                       [opt_field(u'children', check_arguson_blob)])

really_check_arguson_blob = check_blob(arguson_blob_fields)

check_top_arguson_blob = check_blob(arguson_blob_fields +
                                    [field(u'source_id_map', check_source_id_map),
                                     field(u'lineage', check_list(check_lineage_blob))])

# taxomachine only
extended_taxon_blob_fields = (taxon_blob_fields +
                              [field(u'flags', check_list(check_string)),
                               field(u'synonyms', check_list(check_string)),
                               field(u'is_suppressed', check_boolean)])

check_extended_taxon_blob = check_blob(extended_taxon_blob_fields)

check_taxonomy_description_blob = check_blob([field(u'source', check_string),
                                              field(u'author', check_string),
                                              field(u'weburl', check_string),
                                              field(u'name', check_string),
                                              field(u'version', check_string)])

check_match_names_result = (
            check_blob([field(u'governing_code', check_string),  # e.g. "ICN"
                        field(u'unambiguous_names', check_list(check_string)),
                        field(u'unmatched_names', check_list(check_string)),
                        field(u'matched_names', check_list(check_string)),
                        field(u'context', check_string),
                        field(u'includes_approximate_matches', check_boolean),
                        field(u'includes_deprecated_taxa', check_boolean),
                        field(u'includes_suppressed_names', check_boolean),
                        field(u'taxonomy', check_taxonomy_description_blob),
                        field(u'results', check_list(check_blob([
                            field(u'name', check_string),
                            field(u'matches', check_list(check_blob([
                                field(u'matched_name', check_string),
                                field(u'search_string', check_string),
                                field(u'score', check_float), # e.g. 1.0
                                field(u'is_approximate_match', check_boolean),
                                field(u'is_synonym', check_boolean),
                                field(u'nomenclature_code', check_string),
                                field(u'taxon', check_extended_taxon_blob)])))])))]))
