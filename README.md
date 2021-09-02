<!-- markdownlint-disable MD033 -->

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

Binaries are included for macOS, Linux, and Windows for the latest releases. Simply download to your respective platform and put in your path.

## Compiling

If you choose to compile yourself:

1. Install the latest version of [Dart](https://dart.dev/get-dart) for your operating system.
2. Open a terminal.
3. Type the following:

````bash
  cd bin
  dart compile exe uprt.dart -o uprt
````

## Use

For a complete list of options, simply type `uprt` or `uprt -h`

Here is the latest help (version 2021.09.001):

````bash

uprt (2021.09.001 running on windows "Windows 10 Pro" 10.0 (Build 19042))

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
Simply copy the examples given in `uprt -h` and try out the test files.

Below is a demonstration done on Mac Catalina showing the conversion from a .csv file to all formats.
After the conversion the demo scrolls through the resulting files.
<img src="readme-pics/uprt-demo-on-mac-2021-08-31_17-08-09.gif?raw=true" width="800" height="450">

# Exporting/Importing Static Leases

To use uprt, you'll need to know how to export and import your static leases to your router.

Below are the export/import steps for each supported router/firewall type.

## DD-WRT

### Export From Old DD-WRT Router

1. ssh into your router and execute the following to export static leases to the `static_leases` file:

    ````bash
    nvram get static_leases
        ````

2. The static leases will be output to the screen of your terminal and will look something like this:

    ````bash

    F9:CF:5C:08:76:49=aNDCqrh=192.168.0.1=1440 DA:B9:29:92:07:26=wCfxZjSVg=192.168.0.2=1440 C4:4D:02:A0:E1:96=WHis=192.168.0.3=1440 7F:B7:26:C3:A8:D3=FxwzLDsBK=192.168.0.4=1440 FC:D6:B5:48:65:3D=agXCrZIQT=192.168.0.5=1440 F4:34:E2:3A:F9:30=umTiNUO=192.168.0.6=1440 89:2A:F0:C5:2A:30=KnOtLxjPCm=192.168.0.7=1440 A1:C6:4E:4A:E6:96=EfnktBOZWh=192.168.0.8=1440 D1:F4:18:48:A9:C0=vAYoTegH=192.168.0.9=1440 56:A5:2B:40:39:7F=mgeLTnQV=192.168.0.10=1440 28:5B:98:CD:B5:34=vlrZbMUO=192.168.0.11=1440 61:88:68:5E:86:7A=gfrM=192.168.0.12=1440
    ````

   Copy the output from the terminal's screen, paste into a text editor and save to a file.

### Import to New DD-WRT Router

1. Open your browser and login to your new DD-WRT router.
2. Click on the `Services` tab. Keep your browser open so you can view this window at the same time you are importing using ssh.
3. In a separate window, ssh into your new DD-WRT router.
4. Type the following, and press `Enter`,replacing "X" with the number of static leases you are importing.

    ```bash
    nvram set static_leasenum=X
    ````

5. Type the following (but don't press `Enter`):

    ````bash
    nvram set static_leases=""
    ````

6. Copy the list of DD-WRT formatted leases (either from a DD-WRT export or from a file converted using uprt) to your clipboard.  Paste between the quotes shown above coming after 'static_leases'.

    >NOTE: **There seems to be a limit of about 20 leases to copy into the screen. Not sure if  this is a terminal issues or a DD-Wrt issue. See this [thread](https://osdn.net/projects/ttssh2/downloads/74780/teraterm-4.106.exe).**  I've tried both TeraTerm and putty and was unable to resolve the line limit issues.

7. Press 'Enter'.

8. Your leases should now be imported and you should see them listed under the `Services` tab in your open browser. *But they are not saved yet.*
9. Scroll to the bottom of the browser tab and Click on `Save`, then `Apply Settings`. You are done.

## OPEN-WRT

### Export From Open-WRT Router

### Import to New Open-WRT Router
