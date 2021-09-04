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

* Automatic detection of input format based on extension and content; optionally you can specify the format
* Single input file can be simultaneously converted into multiple formats
* Csv and Json files can be used as input
* Validation Checks which removes errors in importing:
  * Validation of output format type
  * Enforced IP range
  * Enforced Checking if each static lease has an IP, Mac,and Host address
  * Duplicate Lease Checking, excluding duplicates from output
  * Validates ip and mac addresses from input file and excludes invalid addresses from the output file

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

## Test Data Included

To test uprt yourself, there are test input files located under the `test/test-data` folder.
Simply copy the examples given in `uprt -h` and try out the test files.

## Video Demo

Below is a demonstration done on Mac Catalina showing the conversion from a .csv file to all formats.
After the conversion the demo scrolls through the resulting files.
<img src="readme-pics/uprt-demo-on-mac-2021-08-31_17-08-09.gif?raw=true" width="800" height="450">

# Exporting amd Importing Static Leases

To use uprt, you'll need to export and import static leases to your router.

Below are the export/import steps for each router/firewall type that is supported by uproot.

## DD-WRT

### DD-WRT - Export

1. Ssh into your router and enter the following on the command line to export static leases to a file:

    ````bash
    nvram get static_leases > static_leases.ddwrt
    ````

2. Download the `static_lease.ddwrt` file from the router by using [WinScp](https://winscp.net) or a similar utility. If you do use WinScp, use the SCP protocol.

3. Alternatively you can simply execute `nvram get static_leases` and copy the output from the terminal, paste it into a text file and save it locally.

4. Now use the exported file as an input file to Uproot and convert to your required format.

Example to convert to OpenWrt format, with a range of static leases between 192.168.0.1 to 192.168.0.254.

````bash
  uprt -i static_leases.ddwrt -b static_leases -g o -L 192.168.0.1 -H 192.168.0.254  
````

### DD-WRT - Import

1. NOTE: Always Make a backup of your DD-WRT software configuration before importing (via backup tab in the Web interface).

2. Using WinSCP (if on Windows) or a similar utility, login to your router and upload the `static_leases.ddwrt` file to the router.
3. Using [Putty](https://www.putty.org/) if on Windows, or other ssh command line client, type the following, and press `Enter`,replacing "X" with the number of static leases you are importing.

    ```bash
    nvram set static_leasenum=X
    ````

4. Type the following and press `Enter`.  Note that the quotes are important:

    ````bash
    nvram set static_leases="$(cat static_leases.ddwrt)"
    nvram commit
    ````

5. Reboot the router. Your static leases should appear under the `Services` tab in the browser interface.
6. Tip: If you have any issues with the above, log in using your browser to your router and view the changes as you make them. For instance, you can click on the `Services` tab and view the static leases after you set the nvram variable. If the `nvram commit` doesn't work try clicking "Save" and then "Apply Settings" in the browser interface.

Video Demo of DD-WRT import:

[![Youtube Demo of DD-WRT Import](readme-pics/ddwrt-youtube-thumb.jpg)](https://www.youtube.com/embed/c-3m4Lm-XjA)

## OpenWrt

### OpenWrt - Export

1. NOTE: Always make a [backup](https://openwrt.org/docs/guide-user/troubleshooting/backup_restore) of your Openwrt Router Files before importing !

2. Using [Putty](https://www.putty.org/) if on Windows, or other ssh command line client, log into your router and type the following:

    ````bash
        grep -hnr -A3 "config host" /etc/config/dhcp > static_leases.openwrt
    ````

3. Check if the resulting contains the static leases:

    ````bash
      cat static_leases.openwrt
    ````

4. To confirm you have all the proper attributes for the static leases, open the /etc/config/dhcp file in vim and compare the resulting output with the "config host" sections in /etc/config/dhcp.

5. Using [scp](https://linuxize.com/post/how-to-use-scp-command-to-securely-transfer-files/) or [WinScp](https://winscp.net) if on Windows, download the `static_leases.openwrt` file.

6. You can use the downloaded file as an input file to Uproot to convert to other formats. Conversely, using Uproot you can convert other formats to this format.

### OpenWrt - Import

1. NOTE: Always Make a [backup](https://openwrt.org/docs/guide-user/troubleshooting/backup_restore) of your Openwrt Router Files before importing !

2. Using [WinSCP](https://winscp.net/) (if on Windows) or a similar scp utility, login to your router and upload the file to be imported to the router (`static_leases.openwrt` in the Open-WRT export example).

3. Using Putty or other ssh command line client, enter the following two lines:

    ````bash
        cp /etc/config/dhcp /etc/config/dhcp.original
        cat *infile.openwrt >> /etc/config/dhcp
    ````

WARNING: Be sure that there are two `>>`, otherwise the dhcp file will be overwritten instead of appended. Thus the recommended backup!

1. Reboot the router. Your static leases should appear under the `Services` tab in the browser interface.

2. Tip: If you have any issues with the above, login using your browser to your router. Static leases should appear in `Network->DHCP and DNS->Static Lease`.  If you don't see the imported leases, repeat steps 2-4 above, viewing the browser window as you make them. After the static leases appear, click `Save & Apply" on the`DHCP and DNS` web page.

Video Demo of Open-WRT import:
[![Youtube Demo of OpenWrt Import](readme-pics/openwrt-youtube-thumb.jpg)](https://www.youtube.com/embed/c-3m4Lm-XjA)

## OPNsense - Exporting

1. Log in to your OPNsense router and navigate to System->Configuration->Backups. Click on the big "Download configuration" button and download the file.

    ![Backups Menu](readme-pics/opn-download-backup.png)

2. The file contains all backup data for the router. However, you only need the data in the static map tags and their parents and related closing tags. Below is an example file containing two static leases and the parent and closing tags. You can delete all other tags and their contents (or copy the staticmap tags you need into a separate file).
  
    ![Backup File Revised to Contain Only Static Map Tags](readme-pics/opn-export-2021-09-03_22-01-54.png)

3. You can use this file as an input file to Uproot to convert to other formats. Conversely, using Uproot you can convert other formats to this format.

## OPNsense - Importing

1. NOTE: Always make a [backup](https://docs.opnsense.org/manual/backups.html) of your OPNsense configuration before importing !

2. Log in to your OPNsense router and navigate to System->Configuration->Backups. Click on the big "Download configuration" button and download the file.

    ![Importing Static Lease Through Restore](readme-pics/opnsense-restore-firefox.png)
