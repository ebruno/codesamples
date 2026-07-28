# SSL Cert Info

This application scans a list of websites and reports the validity of their SSL server certificates relative to a specified date (defaulting to the current date).

## Application Summary

The `sslcertinfo.py` script retrieves SSL certificate details for one or more servers, calculates their validity based on the `notBefore` and `notAfter` dates, and provides a sorted report.

### Key Features:
- Supports multiple servers as input.
- Custom test date for certificate validity verification.
- Ability to sort results by various fields (e.g., `notAfter`, `issuer`, `serialNumber`).
- Outputs results to stdout or a specified file.

## How to Run

To run the application:

1. **Create a Python 3 virtual environment:**
   ```bash
   python3 -m venv venv
   ```

2. **Activate the virtual environment:**
   ```bash
   source venv/bin/activate
   ```

3. **Install the required dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Run the application with the target servers:**
   ```bash
   python3 sslcertinfo.py www.google.com www.apple.com www.mopar.com www.ford.com
   ```

## Usage

Below is the output of the `-h` (help) command:

```text
usage: sslcertinfo [-h] [--date TESTDATE] [--outfile OUTFILE]
                   [--sortby {caIssuers,issuer,notAfter,notBefore,OCSP,serialNumber,subjectAltName,version}]
                   [--version]
                   servers [servers ...]

Report SSL Cert validity based on date. Uses current date as the default.

positional arguments:
  servers               List of servers to query, in the form
                        [https://]servername[:port]

options:
  -h, --help            show this help message and exit
  --date, -d TESTDATE   Date to test the certs against default is now. Date
                        Format is "YYYY MM DD [HH:MM:SS]" in GMT. Date must be
                        quoted. (default: None)
  --outfile, -o OUTFILE
                        Output file (default: sys.stdout)
  --sortby, -s {caIssuers,issuer,notAfter,notBefore,OCSP,serialNumber,subjectAltName,version}
                        Fields to sort by (default: ['notAfter'])
  --version, -v         show program's version number and exit
```

## Execution Output

Below is the output generated when running the application with the specified URLs:

```text
Sorted by: notAfter
Valid relative to date: 2026-07-28 03:22:28.814862+00:00
Site                      Not Valid Before         Not Valid After           Is Valid
www.google.com            Jun 29 08:40:13 2026 GMT Sep 21 08:40:12 2026 GMT  True
www.ford.com              Jun 23 10:48:51 2026 GMT Sep 21 10:48:50 2026 GMT  True
dealerconnect.chrysler.com Jul 17 13:07:53 2026 GMT Oct 15 13:07:52 2026 GMT  True
www.apple.com             Jul  2 22:11:57 2026 GMT Dec 16 18:31:25 2026 GMT  True
```
