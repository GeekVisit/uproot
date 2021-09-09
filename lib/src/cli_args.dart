import 'dart:io';
import 'package:args/args.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as p;
import 'globals.dart' as g;
import 'src.dart';

class CliArgs {
  ArgParser parser = ArgParser();
  ArgResults getArgs(List<String> arguments) {
    try {
      // Note that DefaultsTo only applies if option is not given at all
      parser = ArgParser()
        ..addOption("ip-low-address",
            mandatory: false,
            abbr: 'L',
            help: "Ip4 Lowest Address of Network Range")
        ..addOption("ip-high-address",
            mandatory: false,
            abbr: 'H',
            help: "Ip4 Highest Address of Network Range")
        ..addOption("input-type",
            mandatory: false,
            abbr: 't',
            help: "Input file type:   c (csv), d (ddwrt), j (json),"
                "m (mikrotik), n (opnsense), o (openwrt), p (pfsense)")
        ..addOption("directory-out",
            mandatory: false,
            defaultsTo: p.current,
            abbr: 'd',
            help: "Directory to write files to, defaults to current directory.")
        ..addOption("server",
            mandatory: false,
            defaultsTo: "defconf",
            abbr: 's',
            help: "Name to designate in output file for Mikrotik dhcp server.")
        ..addFlag("write-over",
            defaultsTo: false,
            help: "Overwrite output files, if left out, will not overwrite",
            abbr: "w")
        ..addFlag("help", help: "Help", abbr: "h", callback: (dynamic e) {
          if (e) {
            displayHelp();
          }
        })
        ..addMultiOption("generate-type",
            abbr: 'g',
            defaultsTo: <String>["M"],
            help: "Generated types may be multiple. Valid values include: "
                // ignore: lines_longer_than_80_chars
                " c (csv), d (ddwrt), j (json),"
                "m (mikrotik), n (opnsense), o (openwrt), p (pfsense)")
        ..addOption(
          "base-name",
          abbr: 'b',
          help:
              // ignore: lines_longer_than_80_chars
              "Specify Base Name of Output Files (default use basename of input file)",
          mandatory: false,
        )
        ..addFlag("log", abbr: 'l', defaultsTo: false, help: """
Creates Log file, if -p not set, then location is at '${p.join(Directory.systemTemp.path, "uprt.log")}'""")
        ..addOption("log-file-path",
            abbr: 'p',
            mandatory: false,
            defaultsTo: '${p.join(Directory.systemTemp.path, "uprt.log")}',
            help: "Log error messages to specified file path.")
        ..addFlag("verbose",
            abbr: 'v',
            defaultsTo: false,
            help: "Verbosity - additional debugging messages");

      if (arguments.isEmpty && !g.testRun) {
        displayHelp();
      }

      return parser.parse(arguments);
    } on FormatException {
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
    //TODO - get rid of l and h
    verifyOptions(<String>["L", "H"]);

    /** gets all input files after glob from arguments without flags */
    g.inputFileList = getInputFileList(g.argResults.rest);

    Ip ip = Ip();

    (!ip.isIp4(g.argResults['ip-high-address']) |
            !ip.isIp4(g.argResults['ip-high-address']))
        ? throw Exception("Ip Range Limits are invalid Ip4 addresses.")
        : "";

    if (g.argResults.rest.isEmpty) {
      throw Exception('Required Input File Missing.');
    }
    Directory dir = Directory(g.argResults['directory-out']);
    if (!dir.existsSync()) {
      throw Exception("Output directory ${dir.path} does not exist. ");
    }

    // Set log-file-path to system temp folder if option set

    g.logPath = (g.argResults['log'] &&
            isStringAValidFilePath(g.argResults['log-file-path']))
        ? g.argResults['log-file-path']
        : '${p.join(Directory.systemTemp.path, "uprt.log")}';
  }

  // ignore: slash_for_doc_comments
  /** Gets all input file paths after glob from arguments without flags */
  List<String> getInputFileList(List<String> rest) {
    try {
      List<String> inFiles = <String>[""];

      for (dynamic e in g.argResults.rest) {
        Glob(e).listSync().forEach((dynamic f) {
          (!File(f.absolute.path).existsSync())
              ? inFiles.add(f.absolute.path)
              : throw Exception("Input File ${f.absolute.path} does not exist");
        });
      }
      return g.inputFileList;
    } on Exception {
      rethrow;
    }
  }

  ///  Throws exception if any option value is another option
  /// or a mandatory option is missing
  /// Accepts list of mandatory options as abbreviations
  /// Argparser should not set any mandatory single/multiple options to true as this will handle
  ///
  void verifyOptions([List<String>? requiredOptionsByAbbrs]) {
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
        if (value == "true" || value == "false") {
          continue;
        }
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

      //Check if Mandatory Options Are Missing from Option or Value arguments

      errorMessages = (requiredOptionsByAbbrs != null)
          ? """
$errorMessages${checkForMissingMandatoryOptions(requiredOptionsByAbbrs)}"""
          : errorMessages;

      if (errorMessages != "") {
        throw Exception(errorMessages.trim());
      }
      // ignore: lines_longer_than_80_chars
      /* only if don't use rest which we do   if (g.argResults.rest.isNotEmpty) {
        printMsg("""
${g.newL}${g.newL}Ignoring the following arguments: ${g.argResults.rest.join()}${g.newL}""");
      }*/

    } on Exception {
      rethrow;
    }
  }

// ignore: slash_for_doc_comments
/** Gets input type (j for json, etc) -
// use specified format, if not specified, get from extension,
//if xml look if contains opnsense */
  String getInputType() {
    try {
      if (g.argResults['input-type'] != null) {
        return g.argResults['input-type']!;
      }

      String inputExt = p.extension(g.inputFile).replaceAll(".", "");

      if (inputExt == "xml") {
        return xmlFirewallFormat(); //determines whether opnsense or pfsense
      } else {
        if (g.extToTypes.containsKey(inputExt)) {
          return g.extToTypes[
              inputExt]!; //returns type option associated w/extension
        } else {
          throw Exception(
              """Unable to determine file type, please specify using -t""");
        }
      }
    } on Exception {
      rethrow;
    }
  }

//determines whether xml file is opnsense or pfsense

  String xmlFirewallFormat() {
    return (File(g.inputFile).readAsStringSync().contains("<opnsense>"))
        ? "n"
        : "p";
  }

  String checkForMissingMandatoryOptions(List<String> requiredOptions) {
    try {
      List<String> allowedAbbrevList = parser.options.entries
          .map((dynamic e) => e.value.abbr.toString())
          .toList();

      List<dynamic> optionListNames = g.argResults.options.toList(),
          optionsInValues = g.argResults.options
              .map((dynamic e) => g.argResults[e])
              .where((dynamic e) => (((allowedAbbrevList
                          .contains(e.toString().replaceAll("-", ""))) |
                      (allowedAbbrevList
                          .contains(e.toString().replaceAll("--", ""))))
                  ? true
                  : false))
              // ignore: always_specify_types
              .map((dynamic e) => {
                    if (allowedAbbrevList
                            .contains(e.toString().replaceAll("-", ""))
                        ? true
                        : false)
                      parser
                          .findByAbbreviation(e.toString().replaceAll("-", ""))!
                          .name
                  })
              .map((dynamic e) => e.join())
              .toList();

      List<String> requiredOptionsByName = requiredOptions
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
              !optionListNames.contains(e) && !optionsInValues.contains(e))
          .toList()
          .join(",");

      return (missingMandatoryOptions.isNotEmpty)
          ? "${g.newL}Missing mandatory option(s): $missingMandatoryOptions"
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
