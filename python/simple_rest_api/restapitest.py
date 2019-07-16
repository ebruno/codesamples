#!/usr/bin/env python3

import json
import urllib.parse
from webtest import TestApp


def application(environ,start_response):
    """  REST API to determine if string, potentially a mixture of upper and lower case, numbers, special characters etc.
         contains at least one of each letter of the alphabet.

         :param: environ  environment from the Web Server
         :param: start_response function to setup up the response to client.
    """
    reference_set = set('abcdefghijklnmopqrstuvwxyz')
    
    legal_functions = ['/cleardata/homeworks/hasalphabet']
    response_code = '200 OK'
    body = ''
    json_result = ''
    params = {}
    dict_result = {'result' : False ,'status_detail' : ''}
    result = False
    # Only accept GET Requests.
    #
    try:
        if environ['REQUEST_METHOD'] == 'GET':
            if environ['PATH_INFO'] in legal_functions:
                if environ['PATH_INFO'] == '/cleardata/homeworks/hasalphabet':
                    raw_info = urllib.parse.unquote(environ['QUERY_STRING']).split('&')
                    for item in raw_info:
                        # find the first '=' from the left hand side of string.
                        loc = item.find('=')
                        if loc != -1:
                            key = item[:loc]
                            params[key] = item[loc+1:]
                    try:
                        test_data = set(params['datatocheck'].lower())
                        tmp_results = reference_set - test_data
                        if len(tmp_results) == 0:
                            dict_result['result'] = True
                        else:
                            dict_result['status_detail'] = 'Missing letters: ' + ''.join(sorted(tmp_results))
                    except KeyError as e:
                        dict_result['status_detail'] = 'Required param "datatocheck" not provided'
                        pass
                    except Exception as e:
                        dict_result['status_detail'] = 'Fatal Processing Error'
                        
                    json_result = json.dumps(dict_result,sort_keys=True)
        else:
            response_code = '405 Method Not Allowed'
    except KeyError as e:
        response_code = '400 Bad Request'
        
    body = json_result.encode()
    # add both the Content-Type and Content-Length to headers
    #
    headers = [('Content-Type','application/json;charset=utf8'),('Content-Length',str(len(body)))]
    start_response(response_code,headers)
    return [body]



def main():
    app = TestApp(application)
    tests = ['abcd123','abcdefghijklnmopqrstuvwxyz',
             'abcd123fzut!@#$%^&','abcdefghijkl!n#m$o%p^q6r=7s8tuvwxyz',
             'ABCDEFghijkl!n#m$o%p^q6r7s8tuvwxyz']
    for test_data in tests:
        query_data = {'datatocheck':test_data}
        print('Checking:', test_data)
        resp = app.get('/cleardata/homeworks/hasalphabet',query_data)
        print('Response:')
        print('   - Status      :', '"' + resp.status +'"', 'Integer Value:',resp.status_int)
        print('   - Content-Type:',resp.content_type)
        print('   - headers     :', resp.headers)
        print('   - json        :',resp.json)

if __name__ == '__main__':
    main()
