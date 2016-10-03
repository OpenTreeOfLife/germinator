#!/usr/bin/env python

# This file was copied from the phylesystem-api repo and is intended
# to replace it.

from ConfigParser import SafeConfigParser
from cStringIO import StringIO
import requests
import gzip
import json
import sys
import os

_CONFIG = None
_CONFIG_FN = None
if 'VERBOSE_TESTING' in os.environ:
    try:
        _VERBOSITY_LEVEL = int(os.environ['VERBOSE_TESTING'])
    except:
        _VERBOSITY_LEVEL = 1
else:
    _VERBOSITY_LEVEL = 0
def debug(s):
    if _VERBOSITY_LEVEL > 0:
        sys.stderr.write('testing-harness: {s}\n'.format(s=s))

def config(section=None, param=None, default=None):
    '''
    Returns the config object if `section` and `param` are None, or the 
        value for the requested parameter.
    
    If the parameter (or the section) is missing, the exception is logged and
        None is returned.
    '''
    global _CONFIG, _CONFIG_FN
    if _CONFIG is None:
        _CONFIG_FN = os.path.abspath('test.conf')
        _CONFIG = SafeConfigParser()
        _CONFIG.read(_CONFIG_FN)
        parse_argv_as_options(_CONFIG)
    if section is None and param is None:
        return _CONFIG
    try:
        v = _CONFIG.get(section, param)
        return v
    except:
        if default != None:
            return default
        else:
            sys.stderr.write('Config file "%s" does not contain option "%s" in section "%s"\n' % (_CONFIG_FN, param, section))
            return None

# Obtain command line option assignments given in the form section:parameter=option

def parse_argv_as_options(_CONFIG):
    for arg in sys.argv[1:]:
        equatands = arg.split('=')
        if len(equatands) == 2:
            sec_param = equatands[0].split(':')
            if len(sec_param) == 2:
                if not _CONFIG.has_section(sec_param[0]):
                    _CONFIG.add_section(sec_param[0])
                _CONFIG.set(sec_param[0], sec_param[1], equatands[1])
            else:
                sys.stderr.write('Command line argument %s not in form section:parameter=value' % (arg))
        else:
            sys.stderr.write('Command line argument %s not in form section:parameter=value' % (arg))

def summarize_json_response(resp):
    sys.stderr.write('Sent request to %s\n' %(resp.url))
    raise_for_status(resp)
    try:
        results = resp.json()
    except:
        print 'Non json resp is:', resp.text
        return False
    if isinstance(results, unicode) or isinstance(results, str):
        print results
        er = json.loads(results)
        print er
        print json.dumps(er, sort_keys=True, indent=4)
        sys.stderr.write('Getting JavaScript string. Object expected.\n')
        return False
    print json.dumps(results, sort_keys=True, indent=4)
    return True

def summarize_gzipped_json_response(resp):
    sys.stderr.write('Sent request to %s\n' %(resp.url))
    raise_for_status(resp)
    try:
        uncompressed = gzip.GzipFile(mode='rb', fileobj=StringIO(resp.content)).read()
        results = uncompressed
    except:
        raise 
    if isinstance(results, unicode) or isinstance(results, str):
        er = json.loads(results)
        print json.dumps(er, sort_keys=True, indent=4)
        return True
    else:
        print 'Non gzipped response, but not a string is:', results
        return False

def get_obj_from_http(url,
                      verb='GET',
                      data=None,
                      params=None,
                      headers=None):
    '''Call `url` with the http method of `verb`. 
    If specified `data` is passed using json.dumps
    returns the json content of the web service or raise an HTTP error
    '''
    if headers is None:
        headers = {
            'content-type' : 'application/json',
            'accept' : 'application/json',
        }
    if data:
        resp = requests.request(verb,
                                translate(url),
                                headers=headers,
                                data=json.dumps(data),
                                params=params,
                                allow_redirects=True)
    else:
        resp = requests.request(verb,
                                translate(url),
                                headers=headers,
                                params=params,
                                allow_redirects=True)
    debug('Sent {v} to {s}'.format(v=verb, s=resp.url))
    debug('Got status code {c}'.format(c=resp.status_code))
    if resp.status_code != 200:
        debug('Full response: {r}'.format(r=resp.text))
        raise_for_status(resp)
    return resp.json()

# Returns two results if return_bool_data.
# Otherwise returns one result.

def test_http_json_method(url,
                     verb='GET',
                     data=None,
                     headers=None,
                     expected_status=200,
                     expected_response=None, 
                     return_bool_data=False,
                     is_json=True):
    '''Call `url` with the http method of `verb`. 
    If specified `data` is passed using json.dumps
    returns True if the response:
         has the expected status code, AND
         has the expected content (if expected_response is not None)
    '''
    fail_return = (False, None) if return_bool_data else False
    if headers is None:
        headers = {
            'content-type' : 'application/json',
            'accept' : 'application/json',
        }
    if data:
        resp = requests.request(verb,
                                translate(url),
                                headers=headers,
                                data=json.dumps(data),
                                allow_redirects=True)
    else:
        resp = requests.request(verb,
                                translate(url),
                                headers=headers,
                                allow_redirects=True)
    if resp.status_code != expected_status:
        debug('Sent {v} to {s}'.format(v=verb, s=resp.url))
        debug('Got status code {c} (expecting {e})'.format(c=resp.status_code,e=expected_status))
        debug('Did not get expected response status. Got:\n{s}'.format(s=resp.status_code))
        debug('Full response: {r}'.format(r=resp.text))
        raise_for_status(resp)
        # this is required for the case when we expect a 4xx/5xx but a successful return code is returned
        return fail_return
    if expected_response is not None:
        if not is_json:
             return (True, resp.text) if return_bool_data else True
        try:
            results = resp.json()
            if results != expected_response:
                debug('Did not get expect response content. Got:\n{s}'.format(s=resp.text))
                return fail_return
        except:
            debug('Non json resp is:' + resp.text)
            return fail_return
        if _VERBOSITY_LEVEL > 1:
            debug(unicode(results))
    elif _VERBOSITY_LEVEL > 1:
        debug('Full response: {r}'.format(r=resp.text))
    if not is_json:
             return (True, resp.text) if return_bool_data else True
    return (True, resp.json()) if return_bool_data else True

def raise_for_status(resp):
    try:
        resp.raise_for_status()
    except Exception, e:
        try:
            j = resp.json()
            m = '\n    '.join(['"{k}": {v}'.format(k=k, v=v) for k, v in r.items()])
            sys.stderr.write('resp.json = {t}'.format(t=m))
        except:
            if resp.text:
                sys.stderr.write('resp.text = {t}\n'.format(t=resp.text))
        raise e


def api_is_readonly():
    s = config('host', 'allowwrite', 'false').lower()
    return not (s == 'true')

def exit_if_api_is_readonly(fn):
    if not api_is_readonly():
        return
    if _VERBOSITY_LEVEL > 0:
        debug('Running in read-only mode. Skipped {}'.format(fn))
    # This coordinates with run_tests.sh
    sys.exit(3)

def github_oauth_for_write_or_exit(fn):
    """Pass in the name of test file and get back the OAUTH token from 
    the GITHUB_OAUTH_TOKEN environment if the test is not readonly.
    Otherwise, exit with the exit code (3) that signals tests skipping.
    """
    exit_if_api_is_readonly(fn)
    auth_token = os.environ.get('GITHUB_OAUTH_TOKEN')
    if auth_token is None:
        debug('{} skipped due to lack of GITHUB_OAUTH_TOKEN in env\n'.format(fn))
        # This coordinates with run_tests.sh
        sys.exit(3)
    return auth_token

def writable_api_host_and_oauth_or_exit(fn):
    """Convenience/safety function to makes sure you aren't running
    writable phylesystem tests against the production api server.

    Returns the domain and GITHUB_OAUTH_TOKEN token if the test configuration
        is not readonly, the server is not "https://api.opentree.*" and GITHUB_OAUTH_TOKEN
        is in your env. Otherwise exits with the "skip" test code.
    """
    apihost = config('host', 'apihost').strip()
    if apihost.startswith('https://api.opentree'):
        debug('{} skipped because host is set to production api server. This test must be run locally or against devapi.\n'.format(fn))
        # This coordinates with run_tests.sh
        sys.exit(3)
    auth_token = github_oauth_for_write_or_exit(fn)
    return apihost, auth_token



# Mimic the behavior of apache so that services can be tested without
# having apache running.  See deploy/setup/opentree-shared.conf

translations = [('/v2/study/', '/phylesystem/v1/study/'),
                ('/cached/', '/phylesystem/default/cached/'),
                # treemachine
                ('/v2/graph/', '/db/data/ext/graph/graphdb/'),
                ('/v2/tree_of_life/', '/db/data/ext/tree_of_life/graphdb/'),
                ('/v3/tree_of_life/', '/db/data/ext/tree_of_life_v3/graphdb/'),
                # taxomachine
                ('/taxomachine/v1/', '/db/data/ext/TNRS/graphdb/'),
                ('/v2/tnrs/', '/db/data/ext/tnrs_v2/graphdb/'),
                ('/v2/taxonomy/', '/db/data/ext/taxonomy/graphdb/'),
                ('/v3/tnrs/', '/db/data/ext/tnrs_v3/graphdb/'),
                ('/v3/taxonomy/', '/db/data/ext/taxonomy_v3/graphdb/'),
                # oti
                ('/v3/studies/', '/db/data/ext/studies/graphdb/'),
                ('/v2/studies/', '/db/data/ext/studies/graphdb/'),
                # smasher (port 8081)
                ('/v2/conflict/', '/')
]

def translate(s):
    if config('host', 'translate', 'false') == 'true':
        for (src, dst) in translations:
            if src in s:
                return s.replace(src, dst)
    return s
