# Uproot

uprt (uproot) is a multi-platform (Windows, MacOs, and Linux) command line utility written in Dart to convert static leases between routers. Currently only ip4 static leases are supported.

Current router/firewall software supported:

* DD-WRT
* Json
* Mikrotik
* OPNSense
* OpenWrt
* pfSense

Also supports the following file formats:

* json
* csv

## Features

* checks to see if ip4 and mac addresses in input file are correct and if not excludes them from the output file

* checks to see if all ip addresses are within a valid range provided by user

## Installation

Binaries are included for MacOs, Linux, and Windows for the latest releases. Simply download to your respective platform and put in your path.

## Compiling

If you choose to compile yourself:

1. Install the latest version of [Dart](https://dart.dev/get-dart) for your operating system.
2. Open a terminal.
3. Type the following:

 `cd bin
  dart compile exe uprt.dart -o uprt`

## Use

For a complete list of options, simply type `uprt` or `uprt -h`

Here is the latest help (version 2021-09):

````.

uprt (2021-09 running on windows "Windows 10 Pro" 10.0 (Build 19042))

A tool to migrate static leases between DD-WRT, OpenWrt, OPNsense, Mikrotik, 
and pfSense routers. Also supports cvs and json.

Usage:
-L, --ip-low-address     Ip4 Lowest Address of Network Range
-H, --ip-high-address    Ip4 Highest Address of Network Range
-i, --input-file         Input File to be converted
-t, --input-type         Input file type:   c (csv), d (ddwrt), j (json),m (mikrotik), n (opnsense),
o (openwrt), p (pfsense)
-d, --directory-out      Directory to write files to, defaults to current directory.
                         
-w, --[no-]write-over    Overwrite output files, if left out, will not overwrite
-h, --[no-]help          Help
-g, --generate-type      Generated types may be multiple. Valid values include:  c (csv), d (ddwrt),
j (json),m (mikrotik), n (opnsense), o (openwrt), p (pfsense)
                         (defaults to "M")
-b, --base-name          Base Name of Output Files
-l, --[no-]log           Creates Log file, if -p not set, then location is at 'J:\temp\uprt.log'
-p, --log-file-path      Log error messages to specified file path.

-v, --[no-]verbose       Verbosity - additional debugging messages

Examples:

  Convert Csv file to all formats (csv, ddwrt, json, mikrotik, openwrt, opnsense, pfsense):

  uprt -i test/test-data/lease-list-infile.csv -b converted-output -g cdjmnop -L 192.168.0.1 -H 192.168.0.254 -d test/test-output

  Convert Mikrotik file to json:

  uprt -i test/test-data/lease-list-infile.rsc -b converted-output -g j -L 192.168.0.1 -H 192.168.0.254  -d test/test-output
````

## Demo

To test uprt yourself, there are test input files located under the `test/test-data` folder.
Simply copy any of the examples given in `uprt -h` and try out the test files.

Below is a demonstration done on Mac Catalina showing the conversion from a .csv file to all formats.
After the conversion the demo scrolls through the resulting files.

<img src="readme-pics/uprt-demo-on-mac-2021-08-31_17-08-09.gif?raw=true" width="800" height="450">
