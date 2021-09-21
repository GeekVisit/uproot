import 'dart:io';
import 'package:args/args.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as p;
import 'package:validators/validators.dart';
import 'globals.dart' as g;
import 'src.dart';

class CliArgs {
  ArgParser parser = ArgParser();
  ArgResults getArgs(List<String> arguments) {
    try {
      // Note that DefaultsTo only applies if option is not given at all
      parser = ArgParser()
        ..addOption(
          "base-name",
          abbr: 'b',
          help:
              // ignore: lines_longer_than_80_chars
              "Specify Base Name of Output Files (default uses basename of input file)",
          mandatory: false,
        )
        ..addOption("directory-out", mandatory: false, abbr: 'd', help: """
Directory to write files to, defaults to same directory as input file.""")
        ..addFlag("help", help: "Help", abbr: "h", callback: (dynamic e) {
          if (e) {
            displayHelp();
          }
        })
        ..addOption("input-type",
            mandatory: false,
            abbr: 't',
            help: "Input file type:   c (csv), d (ddwrt), j (json),"
                "m (Mikrotik RouterOS), n (OPNsense), o (OpenWrt), p (pfsense)"
                "If this option is not used, uprt will determine file "
                "type based on the following extensions: .csv, .ddwrt, "
                ".json, .rsc (mikrotik), .xml (for opnsense and pfsense, "
                "distinguishing by searching for <opnsense> in file)")
        ..addMultiOption("generate-type",
            abbr: 'g',
            help: "Generated types may be multiple. Valid values include: "
                // ignore: lines_longer_than_80_chars
                " c (csv), d (DD-WRT), j (json),"
                "m (Mikrotik RouterOS), n (OPNsense), o (OpenWrt), p (pfsense)"
                "Required")
        ..addOption("ip-low-address", mandatory: false, abbr: 'L', help: """
Enforced Lowest Ip of Network Range, Excludes Addresses Lower Than This From Target File""")
        ..addOption("ip-high-address", mandatory: false, abbr: 'H', help: """
Enforced Highest Ip of Network Range, Excludes Addresses Higher Than This From Target File""")
        ..addFlag("log", abbr: 'l', defaultsTo: false, help: """
Creates Log file, if -P not set, then location is at '${p.join(Directory.systemTemp.path, "uprt.log")}'""")
        ..addOption("log-file-path",
            abbr: 'P',
            mandatory: false,
            defaultsTo: '${p.join(Directory.systemTemp.path, "uprt.log")}',
            help: "Full file path to log file.")
        ..addOption("merge", abbr: 'm', mandatory: false, help: """
Merge to file. Specify path to file to merge converted output. 
Used to add static leases to an existing output file.""")
        ..addOption("server",
            mandatory: false,
            defaultsTo: "defconf",
            abbr: 's',
            help: "Name to designate in output file for Mikrotik dhcp server.")
        ..addFlag("verbose", abbr: 'v', help: """
Verbosity - additional messages""")
        ..addFlag("verbose-debug", abbr: 'z', help: """
Verbosity - debug level verbosity""")
        ..addFlag("version", abbr: 'V', help: "Gives Version",
            callback: (dynamic e) {
          if (e) {
            print("${meta["name"]} version ${meta['version']}");
            exit(0);
          }
        })
        ..addFlag("write-over",
            defaultsTo: false,
            help: "Overwrites output files, if left out, will not overwrite",
            abbr: "w");

      if (arguments.isEmpty && !g.testRun) {
        displayHelp();
      }

      return parser.parse(arguments);
    } on FormatException catch (e) {
      if (!testRun) {
        print(e);
        exit(1);
      }
      rethrow;
    } on Exception {
      rethrow;
    }
  }

  void displayHelp() {
    print("""
${meta["name"]} (${meta['version']} running on ${Platform.operatingSystem} ${Platform.operatingSystemVersion})

${meta['description']}

Usage: 
${g.cliArgs.parser.usage}

Examples: 

  Convert a csv file to all formats (csv, json, DD-WRT, Mikrotik, OpenWrt, OPNsense, pfSense):

  uprt -i test/test-data/lease-list-infile.csv -b converted-output -g cdjmnop -L 192.168.0.1 -H 192.168.0.254 -d test/test-output
  
  Convert Mikrotik file to json:

  uprt -i test/test-data/lease-list-infile.rsc -b converted-output -g j -L 192.168.0.1 -H 192.168.0.254  -d test/test-output
  
  """);

    exit(0);
  }

  void checkArgs() {
    try {
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

  // ignore: slash_for_doc_comments
  /** Gets all input file paths after glob from arguments without flags */
  List<String> getInputFileList(List<String> rest) {
    try {
      List<String> inFiles = <String>[];
      for (dynamic e in g.argResults.rest) {
        String fPath = "";

        // converts globlist to absolute path, works with .. */
        List<dynamic> globList = Glob(p.absolute(
                p.normalize(p.absolute(e)).toString().replaceAll(r'\', r'/')))
            .listSync();

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
      List<dynamic> valueList = g.argResults.options
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

// ignore: slash_for_doc_comments
/** Gets format type (j for json, etc) -
 use specified format, if not specified, get from extension,
 if xml look if contains opnsense 
 Returns empty string if unable to be determined. */
  String getFormatTypeOfFile([String filePath = ""]) {
    try {
      if (filePath == "") {
        filePath = g.inputFile;
      }
      if (filePath == g.inputFile && g.argResults['input-type'] != null) {
        return g.argResults['input-type']!;
      }

      String fileExtension = p.extension(filePath);

      if (fileExtension.contains("xml")) {
        return xmlFirewallFormat(); //determines whether opnsense or pfsense
      } else {
        if (g.extToTypes.containsKey(fileExtension)) {
          return g.extToTypes[
              fileExtension]!; //returns type option associated w/extension
        } else {
          throw Exception("""Unable to determine file type" +
               (filePath == g.inputFile) 
               ? "Please specify for input files using -t" 
               : "" 
               """);
        }
      }
    } on Exception {
      rethrow;
    }
  }

// ignore: slash_for_doc_comments
/** Determines whether xml file is opnsense or pfsense 
 * Returns "n" for opnsense and "p" for pfsense
*/

  String xmlFirewallFormat() {
    return (File(g.inputFile).readAsStringSync().contains("<opnsense>"))
        ? "n"
        : "p";
  }

// ignore: slash_for_doc_comments
/** Check if Mandatory Options Are Missing from Option or Value arguments */
  void checkForMissingMandatoryOptions(List<String> requiredOptionsByAbbrs) {
    try {
      List<String> allowedAbbrevList = parser.options.entries
          .map((dynamic e) => e.value.abbr.toString())
          .toList();
      List<dynamic> optionsInValues = g.argResults.options
          .map((dynamic e) => g.argResults[e])
          .where((dynamic e) =>
              (((allowedAbbrevList.contains(e.toString().replaceAll("-", ""))) |
                      (allowedAbbrevList
                          .contains(e.toString().replaceAll("--", ""))))
                  ? true
                  : false))
          // ignore: always_specify_types
          .map((dynamic e) => {
                if (allowedAbbrevList.contains(e.toString().replaceAll("-", ""))
                    ? true
                    : false)
                  parser
                      .findByAbbreviation(e.toString().replaceAll("-", ""))!
                      .name
              })
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

      List<String> requiredOptionsByName = requiredOptionsByAbbrs
          .map((dynamic e) =>
              // ignore: always_specify_types
              {e = parser.findByAbbreviation(e.replaceAll("-", ""))!.name})
          // ignore: always_specify_types
          .map((e) => e.join())
          .toList();

      /// Check for missing options, if in value list, that's ok since will be
      ///  messaged in calling method*/
      String missingMandatoryOptions = requiredOptionsByName
          .where((dynamic e) =>
              missingOptionsOnCommandLine.contains(e) &&
              !optionsInValues.contains(e))
          .toList()
          .join(",");

      (missingMandatoryOptions.isNotEmpty)
          ? throw Exception(
              "${g.newL}Missing mandatory option(s): $missingMandatoryOptions")
          : "";
    } on Exception {
      rethrow;
    }
  }

  List<String> getArgListOfMultipleOptions(dynamic argOption) {
    List<String> types = (argOption[0].length > 1)
        ? argOption[0].split(RegExp(r"b*"))
        : argOption[0].split(",");
    return types;
  }
}
