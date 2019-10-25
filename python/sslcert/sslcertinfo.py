#!/usr/bin/env python3

import os
import sys
import argparse
import ssl
import socket
import hashlib
import types
from urllib.parse import urlsplit
import datetime
import pytz
import platform
if platform.system() == 'Darwin':
    import certifi


# This has been a tested on Ubuntu 18.04 LTS
# on MacOS there is issue python being able to access
# the keystore on my MacMini with Mojave.

# Scan through a list of websites,
# capture SSL Server Certificate security details,
# sort Certificates' data as per their validity, and export data file.
# By validity this is assumed determined by the notBefore date and the not after date
# Can be sorted by
# 'issuer', 'version', 'serialNumber', 'notBefore',
# 'notAfter', 'subjectAltName', 'OCSP', 'caIssuers',
# *Websites sample*
# www.google.com
# www.facebook.com
# www.netflix.com
# www.yahoo.com

version = '0.9.0'

def setup_commandline_options(args=sys.argv):
    help_msgs = {'server': 'List of servers to query, in the form [https://]servername[:port]' }
    parser = argparse.ArgumentParser(prog='sslcertinfo',
                                     formatter_class=argparse.ArgumentDefaultsHelpFormatter,
                                     description='Report SSL Cert validity based on date. Uses current date as the default.')
    parser.add_argument('--date','-d',dest='testdate',type=str,default=None,
                        help='Date to test the certs against default is now. Date Format is "YYYY MM DD [HH:MM:SS]" in GMT')
    parser.add_argument('servers',nargs='+',type=str,help=help_msgs['server'])
    parser.add_argument('--outfile','-o', dest='outfile',default='sys.stdout',help='Output file')
    parser.add_argument('--sortby','-s', dest='sortby',default=['notAfter'],nargs=1,type=str,
                        choices=['caIssuers','issuer', 'notAfter', 'notBefore',
                                 'OCSP', 'serialNumber', 'subjectAltName', 'version'],
                        help='Fields to sort by')
    parser.add_argument('--version','-v',action='version',version='%(prog)s ' + version )
                                    
    return parser

def getthumbprint(site=None,port=443,timeout=5):
    """
    Get thumbprint of system.
    """
    result = {}
    if not isinstance(site,type(None)):
        tmp_sock = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
        tmp_sock.settimeout(timeout)
        wrapped_sock = ssl.wrap_socket(tmp_sock)
        try:
            wrapped_sock.connect((site,port))
            der_cert_bin = wrapped_sock.getpeercert(True)
            result['MD5'] = hashlib.md5(der_cert_bin).hexdigest()
            result['SHA1'] = hashlib.sha1(der_cert_bin).hexdigest()
            result['SHA256'] = hashlib.sha256(der_cert_bin).hexdigest()
        except Exception as e:
            pass
    return result

def get_server_cert_info(site=None,port=443,timeout=5,dateformat='%b %d %H:%M:%S %Y %Z'):
    """
    Get remote systems/server certificate infomation.
    """
    result = None
    if not isinstance(site,type(None)):
        cafile = None
        if platform.system() == 'Darwin':
            cafile = certifi.where()
        ssl_context = ssl.create_default_context(ssl.Purpose.SERVER_AUTH,cafile=cafile)
        tmp_sock = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
        tmp_sock.settimeout(timeout)
        try:
            conn = ssl_context.wrap_socket(tmp_sock, server_side=False,server_hostname=site)
            conn.connect((site, port))
            result  = conn.getpeercert()
            result['notBeforeBinary'] = datetime.time(0,0,0)
            result['notAfterBinary'] = datetime.time(0,0,0)
            try:
                result['notBeforeBinary'] = datetime.datetime.strptime(result['notBefore'],dateformat)
                result['notBeforeBinary'] = result['notBeforeBinary'].replace(tzinfo=pytz.UTC)
                result['notAfterBinary'] = datetime.datetime.strptime(result['notAfter'],dateformat)
                result['notAfterBinary'] = result['notAfterBinary'].replace(tzinfo=pytz.UTC)
            except ValueError as e:
                print(e)
                pass
        except ssl.SSLCertVerificationError as e:
            print(e.library,e.reason)
            print(e.verify_code,e.verify_message)
            pass
        
        except Exception as e:
            print(e)
            pass
    return result

def get_common_name(items=None):
    """
    Locate the tuple with the commonName field and return it's value.
    """
    result = None
    for item in items:
        try:
            idx = item.index('commonName')
            result = item[1]
        except ValueError as e:
            if isinstance(item,tuple):
                result = get_common_name(items=item)
                if not isinstance(result,type(None)):
                    break
            pass
    return result

def is_cert_valid(testdate=None,notBefore=None,notAfter=None):
    """
    Check the certificates valid dates against a specfied time.
    return True or False
    """
    result = False
    if (testdate >= notBefore) and (testdate <= notAfter):
        result = True
    return result
        
    
def report_ssl_info(servers=None,sort_keys=['notBeforeBinary', 'notAfterBinary'],
                    outfile=sys.stdout,testdate=None):
    """ 
    Walk through the serverlist and create the report.
    """
    server_info = []
    for item in servers:
        tmp_val = urlsplit(item)
        if len(tmp_val.scheme) == 0:
            site = urlsplit('https://' + item)
        else:
            site = tmp_val
        port = 443
        if isinstance(site.port,type(None)):
            port = 443
        else:
            port = site.port
        server = get_server_cert_info(site=site.hostname,port=port)
        if isinstance(server,dict):
            server_info.append(server)
    if len(server_info) > 0:
        for sort_key in sort_keys:
            tmp_val = sorted(server_info,key = lambda i: (i[sort_key]))
            tmp_buf = 'Sorted by: {}\n'.format(sort_key.replace('Binary',''))
            outfile.write(tmp_buf)
            tmp_buf = 'Valid relative to date: {}\n'.format(testdate)
            outfile.write(tmp_buf)
            header = '{:<25} {:<24} {:<25} {}'.format('Site','Not Valid Before','Not Valid After','Is Valid')
            if sort_key not in ['notBeforeBinary', 'notAfterBinary']:
                header.replace('\n',' ')
                header += sort_key
            header += '\n'
            outfile.write(header)
            for item in tmp_val:
                common_name = get_common_name(items=item['subject'])
                isvalid = is_cert_valid(testdate=testdate,notBefore=item['notBeforeBinary'],
                                        notAfter=item['notAfterBinary'])
                buffer = '{:<25} {} {}  {}'.format(common_name,item['notBefore'],item['notAfter'],isvalid)
                if sort_key not in ['notBeforeBinary', 'notAfterBinary']:
                    buffer += ' ' + str(item[sort_key])
                buffer += '\n'
                outfile.write(buffer)


def main():
    """
    main get user inport from the command line.
    """
    parser = setup_commandline_options()
    args = parser.parse_args()
    if 'notBefore' in args.sortby:
        args.sortby = ['notBeforeBinary']
    elif 'notAfter' in args.sortby:
        args.sortby = ['notAfterBinary']
    outfile = sys.stdout
    if not args.outfile == 'sys.stdout':
        try:
            outfile = open(args.outfile,"w")
        except IOError as e:
            outfile = None
            pass
        except Exception as e:
            outfile = None
            pass
    if isinstance(args.testdate,type(None)):
        testdate = datetime.datetime.now(datetime.timezone.utc)
    else:
        timefmt = '%Y %m %d %H:%M:%S'
        try:
            testdate = datetime.datetime.strptime(args.testdate,timefmt)
        except ValueError as e:
            try:
                timefmt = '%Y %m %d'
                testdate = datetime.datetime.strptime(args.testdate,timefmt)
            except ValueError as e:
                print("Unable to convert specified date, terminating.")
                testdate = None
                pass
            
        
    if not isinstance(outfile,type(None)) and not isinstance(testdate,type(None)):  
        testdate = testdate.replace(tzinfo=pytz.UTC)
        report_ssl_info(servers=args.servers,outfile=outfile,
                        sort_keys=args.sortby,testdate=testdate)

        if not args.outfile == 'sys.stdout':
            outfile.close()
if __name__ == '__main__':
    main()
