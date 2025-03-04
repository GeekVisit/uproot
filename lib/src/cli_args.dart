// Copyright 2025 GeekVisit All rights reserved.
// Use of this source code is governed by the license in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as p;
import 'package:validators/validators.dart';

import '../lib.dart';
import 'globals.dart' as g;

class CliArgs {
  ArgParser parser = ArgParser();

  ArgResults getArgs(List<String> arguments) {
    try {
      // Note that DefaultsTo only applies if option is not given at all
      parser =
          ArgParser()
            ..addFlag(
              "append",
              abbr: 'a',
              negatable: false,
              help: """
Used when --merge and --sort are given.  If this flag is given, the merged file 
will have the sorted leases from the source file appended to the end of the 
target file leases rather than integrated with the merge file. """,
            )
            ..addOption(
              "base-name",
              abbr: 'b',
              help:
                  // ignore: lines_longer_than_80_chars
                  "Specify Base Name of Output Files (default uses basename of input file)",
              mandatory: false,
            )
            ..addOption(
              "directory-out",
              mandatory: false,
              abbr: 'd',
              help: """
Directory to write files to, defaults to same directory as input file.""",
            )
            ..addOption(
              "fqdn",
              abbr: 'f',
              help:
              // ignore: lines_longer_than_80_chars
              """If option is not specified, default behavior is the relaxed mode. This option requires hostname to meet certain requirements for a domain name. Required options are 'strict' (host name must be fully qualified domain  requiring a tld (e.g., .local, .lan) and alphanumeric characters or hyphen),  "partial" is same as strict but does not require a tld (.e.g., .local). "relaxed" allows underscores and does not require tlds. Any leases with hostnames that do not fit the requirements are not added to the output file. """,
              mandatory: false,
              allowed: ['strict', 'partial', 'relaxed', 'anything-goes'],
            )
            ..addMultiOption(
              "generate-type",
              abbr: 'g',
              help: """
Required. Generated types may be multiple. Valid values include: 
c (csv), d (DD-WRT), j (json),
m (Mikrotik RouterOS), n (OPNsense), o (OpenWrt), p (pfsense), h (piHole)
""",
            )
            ..addFlag(
              "help",
              negatable: false,
              help: "Help",
              abbr: "h",
              callback: (dynamic e) {
                if (e) {
                  displayHelp(1);
                }
              },
            )
            ..addOption(
              "ip-high-address",
              mandatory: false,
              abbr: 'H',
              help: """
Enforced Highest Ip of Network Range, Excludes Addresses Higher Than This From Target File""",
            )
            ..addFlag(
              "log",
              abbr: 'l',
              negatable: false,
              defaultsTo: false,
              help: """
Creates Log file, if -P not set, then location is at '${p.join(Directory.systemTemp.path, "uprt.log")}'""",
            )
            ..addOption(
              "ip-low-address",
              mandatory: false,
              abbr: 'L',
              help: """
Enforced Lowest Ip of Network Range, Excludes Addresses Lower Than This From Target File""",
            )
            ..addOption(
              "mac-delimiter",
              abbr: 'M',
              help:
              // ignore: lines_longer_than_80_chars
              """Specify the delimiter (without quotes) to be used in the out file for mac addresses.The delimiter can be either a colon (:) 8D:EB:29:19:6F:CE), or a hyphen (-) 8D-EB-29-19-6F-CE. If this option is not given, the delimiter will be what is required for the particular output type (e.g., piHole will use hyphen); for generic output types like cvs and json the delimiter will be the same as the input file.""",
              mandatory: false,
              allowed: [':', '-'],
            )
            ..addOption(
              "merge",
              abbr: 'm',
              mandatory: false,
              help: """
Merge to file. Specify path to file to merge converted output. 
Used to add static leases to an existing output file.""",
            )
            ..addOption(
              "log-file-path",
              abbr: 'P',
              mandatory: false,
              defaultsTo: '${p.join(Directory.systemTemp.path, "uprt.log")}',
              help: "Full file path to log file.",
            )
            ..addFlag(
              "replace-duplicates-in-merge-file",
              negatable: false,
              defaultsTo: false,
              abbr: 'r',
              help: """
Applies only when using --merge. If this option is set and the source file 
has a static lease which has the same mac address, ip or hostname as a lease in
the merge file, the lease or leases in the merge file that have any of the
duplicate components will be discarded and the input lease will be used.  
By default, this is set to false so any lease in the input file that has the 
same ip, hostname, or mac address as one in the merge file is discarded.""",
            )
            ..addFlag(
              "sort",
              abbr: 's',
              negatable: true,
              defaultsTo: true,
              help: """
Leases in resulting output file are sorted by Ip address.""",
            )
            ..addOption(
              "server",
              mandatory: false,
              defaultsTo: "defconf",
              abbr: 'S',
              help:
                  "Name to designate in output file for Mikrotik dhcp server.",
            )
            ..addOption(
              "input-type",
              mandatory: false,
              abbr: 't',
              help: """
Input file type:   c (csv), d (ddwrt), j (json),
m (Mikrotik RouterOS), n (OPNsense), o (OpenWrt), p (pfsense), h (piHole)
If this option is not used, uprt will try to determine file 
type based on the following extensions: .csv, .ddwrt, 
.json, .rsc (mikrotik), .xml (for opnsense and pfsense, 
distinguishing by searching for <opnsense> in file)""",
            )
            ..addFlag(
              "verbose",
              abbr: 'v',
              negatable: false,
              help: """
Verbosity - additional messages""",
            )
            ..addFlag(
              "version",
              negatable: false,
              abbr: 'V',
              help: "Gives Version",
              callback: (dynamic e) {
                if (e) {
                  print("${meta["name"]} version ${meta['version']}");
                  exit(0);
                }
              },
            )
            ..addFlag(
              "write-over",
              defaultsTo: false,
              negatable: false,
              help: "Overwrites output files, if left out, will not overwrite",
              abbr: "w",
            )
            ..addFlag(
              "verbose-debug",
              abbr: 'z',
              negatable: false,
              help: """
Verbosity - debug level verbosity""",
            );

      if (arguments.isEmpty) {
        displayHelp(1);
      }

      return parser.parse(arguments);
    } on FormatException catch (e) {
      if (!g.testRun) {
        ;
        print(
          "${g.newL}${g.colorError}Improper Usage - check help: "
          "${e.message.toString().replaceFirst("""
FormatException: """, "")}${g.ansiFormatEnd}",
        );
        exit(1);
      } else {
        rethrow;
      }
    } on Exception {
      rethrow;
    }
  }

  void displayHelp(int errorCode) {
    try {
      //NOTE: Can't use printMsg here because argResults has not been
      displayTextWithAutoPause("""
${meta["name"]} (${meta['version']} running on ${Platform.operatingSystem} ${Platform.operatingSystemVersion})

${meta['description']}

Usage: 
 
 uprt <input_file_path> -g <c|d|j|m|n|o|p|h> -d <output file> [options]

${g.cliArgs.parser.usage}

${g.ansiBold}Examples${g.ansiFormatEnd}: 

${g.ansiBold}Convert a csv file to all formats (csv, json, DD-WRT, Mikrotik, OpenWrt, OPNsense, pfSense, piHole)${g.ansiFormatEnd}:

  uprt test/test-data/lease-list-infile.csv -g cdjmnoph -d test/test-output

${g.ansiBold}Convert multiple csv files to PfSense and saving output to a specified directory${g.ansiFormatEnd}:

  uprt test/test-data/*.csv -g p -d test/test-output

${g.ansiBold}Convert a csv file to all formats, stripping out all leases that do not have a hostname that is a fully qualified domain name, stripping out leases not in range, and saving output to specified directory${g.ansiFormatEnd}: 

  uprt test/test-data/lease-list-infile.csv -f strict -b converted-output -g cdjmnoph -L 192.168.0.1 -H 192.168.0.254 -d test/test-output
  
${g.ansiBold}Convert a csv file from one that uses colons in mac addresses to a json file that has hyphens.${g.ansiFormatEnd}: 

  uprt test/test-data/lease-list-infile.csv -M - -b converted-output -g j -d test/test-output

${g.ansiBold}Merging leases in a CSV file with an existing DDWRT file and generating an OpnSense file${g.ansiFormatEnd}:

    uprt test/test-data/lease-list-infile.csv -m test/test-merge/lease-list-infile-merge.ddwrt -g n -b example-merge-output -d test/test-output




  
${g.ansiBold}Make a full backup of your router/firewall before importing any files generated by uprt. Use of uprt and files generated by uprt is entirely at user's risk. ${g.ansiFormatEnd}
  """);

      if (!g.testRun) {
        exit(errorCode);
      }
    } on Exception {
      rethrow;
    }
  }

  void displayTextWithAutoPause(String text) {
    if (g.testRun) {
      printMsg(text);
      return;
    }
    final terminalHeight = 20;
    final lines = text.split('\n');
    int lineNumber = 0;

    for (final line in lines) {
      stdout.writeln(line);
      lineNumber++;

      if (lineNumber >= terminalHeight) {
        stdout.write('Press Return to continue...');
        stdin.readLineSync();
        lineNumber = 0;
        /* stdout.write(
          '\x1B[2J\x1B[H',
        );
        */
        // Clear screen and move cursor to top-left
      }
    }
  }

  void checkArgs() {
    try {
      g.verbose = (g.argResults['verbose-debug'] || g.argResults['verbose']);
      g.fqdnStrictLevel = g.argResults['fqdn'] ?? 'relaxed';
      checkIfOptionArgsAreGiven();
      checkForMissingMandatoryOptions(<String>["g"]);
      validateIpRangeOptions();
      checkIfInputFileGiven();
    } on Exception {
      rethrow;
    }
  }

  void checkIfInputFileGiven() {
    if (g.argResults.rest.isEmpty) {
      throw Exception('Required Input File Missing.');
    }
  }

  void validateIpRangeOptions() {
    try {
      (g.argResults['ip-high-address'] != null &&
              g.argResults['ip-low-address'] != null &&
              !isIP(g.argResults['ip-low-address'], 4))
          ? throw Exception("Ip Range Limit(s) are invalid Ip4 addresses.")
          : "";
    } on Exception {
      rethrow;
    }
  }

  /// Gets all input file paths after glob from arguments without flags
  List<String> getInputFileList(List<String> rest) {
    try {
      List<String> inFiles = <String>[];
      for (dynamic e in g.argResults.rest) {
        String fPath = "";

        // converts globlist to absolute path, works with .. */
        List<dynamic> globList =
            Glob(
              p.absolute(
                p.normalize(p.absolute(e)).toString().replaceAll(r'\', r'/'),
              ),
            ).listSync();

        if (globList.isEmpty) {
          throw Exception("Source file \"$e\" not found");
        }
        // ignore: avoid_function_literals_in_foreach_calls
        globList.forEach((dynamic f) {
          fPath = p.canonicalize(f.absolute.path);
          (File(fPath).existsSync())
              ? inFiles.add(fPath)
              : throw Exception("Input File $fPath does not exist");
        });
      }

      return inFiles;
    } on Exception {
      rethrow;
    }
  }

  ///  Throws exception if any option value is another option
  /// or a mandatory option is missing
  /// Accepts list of mandatory options as abbreviations
  /// Argparser should not set any mandatory single/multiple options to true as this will handle
  ///
  void checkIfOptionArgsAreGiven() {
    try {
      String errorMessages = "";
      List<dynamic> valueList =
              g.argResults.options
                  .toList()
                  .map((dynamic e) => g.argResults[e])
                  .toList(),
          optionList = g.argResults.options.toList(),
          allowedOptionList = parser.options.keys.toList(),
          allowedAbbrevList =
              parser.options.entries.map((dynamic e) => e.value.abbr).toList();

      for (int i = 0; i < valueList.length; i++) {
        String value = valueList[i].toString(), optionName = optionList[i];
        // skip flags, just looking for arguments
        if (value == "true" || value == "false") {
          continue;
        }
        //if the argument is an option then give error
        if (value.substring(0, 1) == "-" &&
            (allowedOptionList.contains(value.replaceAll("--", "")) ||
                allowedAbbrevList.contains(value.replaceAll("-", "")))) {
          errorMessages =
              (errorMessages != "") ? "$errorMessages${g.newL}" : "";
          errorMessages =
              "$errorMessages$optionName is missing argument and is set "
              "to $value.";
        }
      }

      if (errorMessages != "") {
        throw Exception(errorMessages.trim());
      }
    } on Exception {
      rethrow;
    }
  }

  /// Determines the input type abbreviation based on the provided file path.
  ///
  /// If no file path is provided, it defaults to using the global input file path.
  /// The method first checks if the input type is specified in the argument results.
  /// If not, it attempts to determine the input type based on the file extension.
  ///
  /// - [filePath]: The path of the file for which the input type abbreviation is to be determined.
  ///   Defaults to an empty string.
  ///
  /// Returns the input type abbreviation as a [String].
  /// If the file type cannot be determined, it prints an error message and returns 'Z'.
  ///
  /// Throws an [Exception] if an error occurs during the process.
  String? getInputTypeAbbrev([String filePath = ""]) {
    try {
      if (filePath == "") {
        filePath = g.inputFile;
      }
      if (filePath == g.inputFile && g.argResults['input-type'] != null) {
        return g.argResults['input-type'];
      }

      Set<String> allowedExtensionTypes = g.extToAbbrev.keys.toSet();

      String fileExtension = p.extension(filePath);

      if (allowedExtensionTypes.contains(fileExtension)) {
        return g.extToAbbrev[fileExtension]!;
      }

      String hyphenatedExtension = getHyphenatedExtension(filePath);

      if ((allowedExtensionTypes.contains(hyphenatedExtension))) {
        return g.extToAbbrev[hyphenatedExtension];
        //returns type option associated w/extension
      }

      String errMsg =
          (filePath == g.inputFile)
              // ignore: lines_longer_than_80_chars
              ? "Please use only extensions specified in help or specify file type using -t"
              : "";
      errMsg = """Unable to determine file type for $filePath $errMsg""";

      printMsg(errMsg);
      return 'Z'; //no file type
    } on Exception {
      rethrow;
    }
  }

  /// Extracts the hyphenated extension from a given file name.
  ///
  /// This method uses a regular expression to find a hyphenated extension
  /// in the format `-extension` followed by a period and any other characters.
  ///
  /// If a match is found, the entire matched string is returned.
  /// If no match is found, the string 'NO-MATCH-FOUND' is returned.
  ///
  /// Example:
  /// ```dart
  /// String extension = getHyphenatedExtension('example-file-name-abc.txt');
  /// print(extension); // Output: -abc.txt
  /// ```
  ///
  /// - Parameter fileName: The name of the file from which to extract the hyphenated extension.
  /// - Returns: The hyphenated extension if found, otherwise 'NO-MATCH-FOUND'.
  String getHyphenatedExtension(String fileName) {
    RegExp regExpHyphenExtension = RegExp(r'-(\w+)\.[^.]+$');
    RegExpMatch? match = regExpHyphenExtension.firstMatch(fileName);

    if (match != null) {
      String returnValue = match.group(0)!;
      return returnValue;
    } else {
      return 'NO-MATCH-FOUND'; // Return an empty string or handle the case where no match is found
    }
  }

  /// Check if Mandatory Options Are Missing from Option or Value arguments
  void checkForMissingMandatoryOptions(List<String> requiredOptionsByAbbrs) {
    try {
      List<String> allowedAbbrevList =
          parser.options.entries
              .map((dynamic e) => e.value.abbr.toString())
              .toList();
      List<dynamic> optionsInValues =
          g.argResults.options
              .map((dynamic e) => g.argResults[e])
              .where(
                (dynamic e) =>
                    (((allowedAbbrevList.contains(
                              e.toString().replaceAll("-", ""),
                            )) |
                            (allowedAbbrevList.contains(
                              e.toString().replaceAll("--", ""),
                            )))
                        ? true
                        : false),
              )
              // ignore: always_specify_types
              .map(
                (dynamic e) => {
                  if (allowedAbbrevList.contains(
                        e.toString().replaceAll("-", ""),
                      )
                      ? true
                      : false)
                    parser
                        .findByAbbreviation(e.toString().replaceAll("-", ""))!
                        .name,
                },
              )
              .map((dynamic e) => e.join())
              .toList();
      List<String> optionListNames = parser.options.keys.toList();

      List<String> missingOptionsOnCommandLine = <String>[];
      for (int x = 0; x < optionListNames.length; x++) {
        if (g.argResults[optionListNames[x]] is bool) continue;

        if (g.argResults[optionListNames[x]] == null ||
            g.argResults[optionListNames[x]].length == 0) {
          missingOptionsOnCommandLine.add(optionListNames[x]);
        }
      }

      List<String> requiredOptionsByName =
          requiredOptionsByAbbrs
              .map(
                (dynamic e) =>
                // ignore: always_specify_types
                {e = parser.findByAbbreviation(e.replaceAll("-", ""))!.name},
              )
              // ignore: always_specify_types
              .map((e) => e.join())
              .toList();

      /// Check for missing options, if in value list, that's ok since will be
      ///  messaged in calling method*/
      String missingMandatoryOptions = requiredOptionsByName
          .where(
            (dynamic e) =>
                missingOptionsOnCommandLine.contains(e) &&
                !optionsInValues.contains(e),
          )
          .toList()
          .join(",");

      (missingMandatoryOptions.isNotEmpty)
          ? throw Exception(
            "${g.newL}Missing mandatory option(s): $missingMandatoryOptions",
          )
          : "";
    } on Exception {
      rethrow;
    }
  }

  List<String> getArgListOfMultipleOptions(dynamic argOption) {
    List<String> types =
        (argOption[0].length > 1)
            ? argOption[0].split(RegExp(r"b*"))
            : argOption[0].split(",");
    return types;
  }
}
