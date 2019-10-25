## SSL Cert Info ##

This has been a tested on Ubuntu 18.04 LTS and Mac OS X Mojave.
Requires the pytz package and on MacOS X Mojave the certifi package.

      usage: sslcertinfo [-h] [--date TESTDATE] [--outfile OUTFILE]
                       [--sortby {caIssuers,issuer,notAfter,notBefore,OCSP,serialNumber,subjectAltName,version}]
                       [--version]
                       servers [servers ...]

      Report SSL Cert validity based on date. Uses current date as the default.

      positional arguments:
      servers               List of servers to query, in the form
                            [https://]servername[:port]

      optional arguments:
      -h, --help            show this help message and exit
      --date TESTDATE, -d TESTDATE
                           Date to test the certs against default is now. Date
                           Format is "YYYY MM DD [HH:MM:SS]" in GMT (default:
                           None)
      --outfile OUTFILE, -o OUTFILE
                            Output file (default: sys.stdout)
      --sortby {caIssuers,issuer,notAfter,notBefore,OCSP,serialNumber,subjectAltName,version}, -s {caIssuers,issuer,notAfter,notBefore,OCSP,serialNumber,subjectAltName,version}
                           Fields to sort by (default: ['notAfter'])
     --version, -v         show program's version number and exit

## Sample Run output to file ##

       ./sslcertinfo.py --outfile demoresults.txt  www.google.com www.apple.com www.netflix.com www.yahoo.com www.dropbox.com  www.facebook.com
       ls *.txt
       demoresults.txt
       cat demoresults.txt 
       Sorted by: notAfter
       Valid relative to date: 2019-10-24 02:50:53.634573+00:00
       Site                      Not Valid Before         Not Valid After           Is Valid
       *.facebook.com            Sep 22 00:00:00 2019 GMT Dec 20 12:00:00 2019 GMT  True
       www.google.com            Oct 10 20:56:23 2019 GMT Jan  2 20:56:23 2020 GMT  True
       www.netflix.com           Feb  7 00:00:00 2018 GMT Feb  7 12:00:00 2020 GMT  True
       www.dropbox.com           Nov 14 00:00:00 2017 GMT Feb 11 12:00:00 2020 GMT  True
       *.www.yahoo.com           Aug 23 00:00:00 2019 GMT Feb 19 12:00:00 2020 GMT  True
       www.apple.com             Mar  7 00:00:00 2019 GMT Mar  7 12:00:00 2020 GMT  True


## Sample Run output to console/stdout ##

     ./sslcertinfo.py  www.google.com www.apple.com www.netflix.com www.yahoo.com www.dropbox.com  www.facebook.com
     Sorted by: notAfter
     Valid relative to date: 2019-10-24 02:48:54.192084+00:00
     Site                      Not Valid Before         Not Valid After           Is Valid
     *.facebook.com            Sep 22 00:00:00 2019 GMT Dec 20 12:00:00 2019 GMT  True
     www.google.com            Oct 10 20:56:23 2019 GMT Jan  2 20:56:23 2020 GMT  True
     www.netflix.com           Feb  7 00:00:00 2018 GMT Feb  7 12:00:00 2020 GMT  True
     www.dropbox.com           Nov 14 00:00:00 2017 GMT Feb 11 12:00:00 2020 GMT  True
     *.www.yahoo.com           Aug 23 00:00:00 2019 GMT Feb 19 12:00:00 2020 GMT  True
     www.apple.com             Mar  7 00:00:00 2019 GMT Mar  7 12:00:00 2020 GMT  True


