# ChangeLog for [Uproot](https://github.com/GeekVisit/uproot) (uprt)

## 2025.03.001

### Added
  
* Added support for piHole static leases
* Added support for exporting and importing host names for Mikrotik leases
* Added -f option to adjust level of domain strictness required of hosts in input file; if lease having host does not meet requirement, lease is stripped from output file
* Added -M option to select colon or dash as delimiter character in mac addresses

### Changed

* Where output file type requires it, empty hostnames are now filled in by dashed mac address
* By default, host names must meet "relaxed" requirements of domain names (no tlds required, underscores allowed, but otherwise character requirements enforced).  Requirements can be changed with the -f option

### FixeD

* Fixed github issues #2,3 (lease conversions),6 (pihole)bug fixes

### Documentation

* Updated documentation to reflect changes

## 2021.10.001 (beta)

**Initial Release.**

Features and options:

````bash

uprt (2021.10.001 running on macos 10.15.7)


A tool to migrate static leases between DD-WRT, OpenWrt, OPNsense, Mikrotik, and pfSense routers. Also supports csv and json.

Usage:
-a, --append                              Used when --merge and --sort are given.  If this flag is given, the merged file
                                          will have the sorted leases from the source file appended to the end of the
                                          target file leases rather than integrated with the merge file.
-b, --base-name                           Specify Base Name of Output Files (default uses basename of input file)
-d, --directory-out                       Directory to write files to, defaults to same directory as input file.
-h, --help                                Help
-t, --input-type                          Input file type:   c (csv), d (ddwrt), j (json),
                                          m (Mikrotik RouterOS), n (OPNsense), o (OpenWrt), p (pfsense)
                                          If this option is not used, uprt will try to determine file
                                          type based on the following extensions: .csv, .ddwrt,
                                          .json, .rsc (mikrotik), .xml (for opnsense and pfsense,
                                          distinguishing by searching for <opnsense> in file)
-g, --generate-type                       Required. Generated types may be multiple. Valid values include:
                                          c (csv), d (DD-WRT), j (json),
                                          m (Mikrotik RouterOS), n (OPNsense), o (OpenWrt), p (pfsense)
-L, --ip-low-address                      Enforced Lowest Ip of Network Range, Excludes Addresses Lower Than This From Target File
-H, --ip-high-address                     Enforced Highest Ip of Network Range, Excludes Addresses Higher Than This From Target File
-l, --log                                 Creates Log file, if -P not set, then location is in temp folder
-P, --log-file-path                       Full file path to log file.
-m, --merge                               Merge to file. Specify path to file to merge converted output.
                                          Used to add static leases to an existing output file.
-S, --server                              Name to designate in output file for Mikrotik dhcp server.
                                          (defaults to "defconf")
-r, --replace-duplicates-in-merge-file    Applies only when using --merge. If this option is set and the source file
                                          has a static lease which has the same mac address, ip or hostname as a lease in
                                          the merge file, the lease or leases in the merge file that have any of the
                                          duplicate components will be discarded and the input lease will be used.
                                          By default, this is set to false so any lease in the input file that has the
                                          same ip, hostname, or mac address as one in the merge file is discarded.
-s, --[no-]sort                           Leases in resulting output file are sorted by Ip address.
                                          (defaults to on)
-v, --verbose                             Verbosity - additional messages
-z, --verbose-debug                       Verbosity - debug level verbosity
-V, --version                             Gives Version
-w, --write-over                          Overwrites output files, if left out, will not overwrite
````

## Versioning

   Uprt uses calendar versioning:

   1st number: 4 Year
   2nd number: 2 digit Month
   3rd number: 3 digit small patch number

## Unreleased/planned changes

* gui version
* man page

## Types of changes

  `Added` for new features.
  `Changed` for changes in existing functionality.
  `Deprecated` for soon-to-be removed features.
  `Removed` for now removed features.
  `Fixed` for any bug fixes.
  `Security` in case of vulnerabilities.
