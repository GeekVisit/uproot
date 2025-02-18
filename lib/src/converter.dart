// Copyright 2021 GeekVisit All rights reserved.
// Use of this source code is governed by the license in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;

import '../lib.dart';
import 'globals.dart' as g;

class Converter {
  /// Main loop - process each file argument

  String outPath = "";

  /// Output files that have been saved to prevent overwriting
  List<String> outputFilesSaved = <String>[];

  /// Main loop to convert all files on command line
  void convertFileList(List<String> arguments) {
    try {
      initialize(arguments);
      g.inputFileList = g.cliArgs.getInputFileList(g.argResults.rest);
      printMsg("Uprt converting files ...");
      for (String eachFilePath in g.inputFileList) {
        setInputFile(eachFilePath);
        printMsg("Scanning ${p.basename(eachFilePath)}...");

        toOutput();
      }
    } on Exception {
      rethrow;
    }
  }

  void setInputFile(String inputFilePath) {
    try {
      g.inputFile = inputFilePath;

      g.baseName =
          (g.argResults['base-name'] == null || g.argResults['base-name'] == "")
              ? p.basenameWithoutExtension(g.inputFile)
              : g.argResults['base-name'];

      g.inputType = g.cliArgs.getFormatTypeOfFile();
    } on Exception {
      return;
    }
  }

  void toOutput() {
    try {
      /**  split type argument regardless of comma separator*/
      List<String> outputTypes =
          g.cliArgs.getArgListOfMultipleOptions(g.argResults['generate-type']);

      for (dynamic eachOutputType in outputTypes) {
        switch (eachOutputType) {
          case 'c':
            saveAndValidateOutFile(
                toCsv(), Csv(), g.fFormats.csv.abbrev, g.fFormats.csv.fileExt);
            break;

          case 'd':
            saveAndValidateOutFile(toDdwrt(), Ddwrt(), g.fFormats.ddwrt.abbrev,
                g.fFormats.ddwrt.fileExt);
            break;

          case 'j':
            saveAndValidateOutFile(toJson(), Json(), g.fFormats.json.abbrev,
                g.fFormats.json.fileExt);
            break;

          case 'm':
            saveAndValidateOutFile(toMikroTik(), Mikrotik(),
                g.fFormats.mikrotik.abbrev, g.fFormats.mikrotik.fileExt);
            break;

          case 'n':
            saveAndValidateOutFile(toOpnSense(), OpnSense(),
                g.fFormats.opnsense.abbrev, "${g.fFormats.opnsense.fileExt}");

            break;

          case 'o':
            saveAndValidateOutFile(toOpenWrt(), OpenWrt(),
                g.fFormats.openwrt.abbrev, g.fFormats.openwrt.fileExt);
            break;

          case 'p':
            saveAndValidateOutFile(toPfsense(), PfSense(),
                g.fFormats.pfsense.abbrev, "${g.fFormats.pfsense.fileExt}");

            break;

          case 'Z': //unable to determine file type
            break;
          default:
            printMsg("Incorrect Output type: $eachOutputType.", errMsg: true);
            break;
        }
      }
    } on Exception catch (e) {
      if (e.toString().contains("is invalid format")) {
        printMsg(e);
        return;
      }
      rethrow;
    }
  }

  /// Save converted contents to outFile path and check if valid
  void saveAndValidateOutFile(String fileContents, FileType outputClass,
      String outputFormatName, String outputExt) {
    try {
      setOutPath(outputExt);
      printMsg("Validating output ...", onlyIfVerbose: true);
      printCompletedAll(outputFormatName,
          success: (fileContents != "" &&
              outputClass.isContentValid(fileContents: fileContents) &&
              saveToOutPath(fileContents)));
    } on Exception {
      rethrow;
    }
  }

  /// Saves Converted Output file
  bool saveToOutPath(String outContents) {
    /** Don't save over files previously saved in same run if happen to have
     *  same name, overrides write-over command line option*/
    try {
      bool overWrite = (outputFilesSaved.contains(outPath))
          ? false
          : g.argResults['write-over'];

      outPath = saveFile(outContents, outPath, overWrite: overWrite);
      outputFilesSaved.add(outPath);
      return true;
    } on Exception {
      return false;
    }
  }

  /// Builds output path for generated filed given the output extension
  void setOutPath(String outputExt) {
    // Sets output directory to g.dirname or if not specified then input dir
    g.dirOut = (g.argResults['directory-out'] == null ||
            g.argResults['directory-out'] == "")
        ? p.dirname(g.inputFile)
        : g.argResults['directory-out'];

    if (!Directory(g.dirOut).existsSync()) {
      throw Exception("Output directory ${g.dirOut} does not exist. ");
    }

    outPath =
        p.canonicalize("${File(p.join(g.dirOut, g.baseName)).absolute.path}"
            "$outputExt");
  }

  void printCompletedAll(String fileType, {bool success = true}) {
    String displaySourceFile =
        (g.verbose) ? p.canonicalize(g.inputFile) : p.basename(g.inputFile);
    String displayTargetFile =
        (g.verbose) ? p.canonicalize(outPath) : p.basename(outPath);
    String successResult = (success)
        ? "${g.colorSuccess}Successful${g.ansiFormatEnd}"
        : "${g.newL}${g.colorError}$displayTargetFile failed to validate and "
            """
save. Check that source file is properly formatted.${g.ansiFormatEnd}""";

    printMsg("""
$displaySourceFile =>>> $displayTargetFile (${g.typeOptionToName[g.inputType]} => ${g.typeOptionToName[fileType]}) $successResult""");
  }

  /// Initializes programs - does some validation of arguments
  /// and meta, and sets up log

  void initialize(List<String> arguments) {
    MetaUpdate("pubspec.yaml").verifyCodeHasUpdatedMeta();

    g.argResults = g.cliArgs.getArgs(arguments);
    g.cliArgs.checkArgs();
    setLogPath();

    if (g.logPath != "") {
      String logMessage =
          '''${meta['name']} (${meta['version']} running on ${Platform.operatingSystem} ${Platform.operatingSystemVersion} Locale: ${Platform.localeName})${g.newL}''';

      printMsg(logMessage, logOnly: true);
    }
  }

  /// Set log-file-path to system temp folder if option set
  void setLogPath() {
    try {
      g.logPath = (g.argResults['log'] &&
              isStringAValidFilePath(g.argResults['log-file-path']))
          ? g.argResults['log-file-path']
          : '${p.join(Directory.systemTemp.path, "uprt.log")}';
          
      if (File(g.logPath).existsSync()) {
        //delete old log
        File(g.logPath).deleteSync();
      }
    } on Exception {
      rethrow;
    }
  }

  /// Post Conversion Cleanup
  static void cleanUp() {
    try {
      if (g.tempDir.existsSync()) g.tempDir.deleteSync(recursive: true);
      if (g.argResults['log']) {
        printMsg("Log is at ${g.argResults['log-file-path']}");
      }
      printMsg(
          "******************${g.newL}Make a full backup of your router/firewall before importing any files generated by uprt. Use of uprt and files generated by uprt is entirely at user's risk.");
    } on Exception {
      rethrow;
    }
  }

  /// Gets the temporary LeaseMap from json file and Merge if Option Given

  Map<String, List<String>> getSourceLeaseMap() {
    Map<String, List<String>> inputLeaseMap = g.inputTypeCl[g.inputType]!
        .getLeaseMap(
            fileContents: getFileContents(g.inputFile),
            fileLines: File(g.inputFile).readAsLinesSync(),
            removeBadLeases: true);

    inputLeaseMap = (g.argResults['merge'] != null)
        ? <String, List<String>>{
            ...mergeLeaseMapWithFile(
                inputLeaseMap, getGoodPath(g.argResults['merge']))
          }
        : inputLeaseMap;

    return (g.argResults['sort'] &&
            !g.argResults['append'] &&
            !ValidateLeases().areAllLeaseMapValuesEmpty(inputLeaseMap))
        ? sortLeaseMapByIp(inputLeaseMap)
        : inputLeaseMap;
  }

  /// Builds Csv String from input File and Merge File
  String toCsv() {
    return Csv().build(getSourceLeaseMap());
  }

  /// Builds Ddwrt String from input File and Merge File
  String toDdwrt() {
    return Ddwrt().build(getSourceLeaseMap());
  }

  /// Builds Json String from input & merge file

  String toJson() {
    return Json().build(getSourceLeaseMap());
  }

  /// Builds OpenWrt String from input and merge File
  String toOpenWrt() {
    return OpenWrt().build(getSourceLeaseMap());
  }

  /// Builds Mikrotik String from input and merge File
  String toMikroTik() {
    return Mikrotik().build(getSourceLeaseMap());
  }

  /// Builds OpnSense from input and merge File

  String toPfsense() {
    return PfSense().build(getSourceLeaseMap());
  }

  /// Builds OpnSense String from OpnSense File and Merge File
  String toOpnSense() {
    return OpnSense().build(getSourceLeaseMap());
  }

  Map<String, List<String>> sortLeaseMapByIp(
      Map<String, List<String>> leaseMap) {
    try {
      List<String> leaseList = flattenLeaseMap(leaseMap, sort: true);

      return explodeLeaseList(leaseList);
    } on Exception {
      rethrow;
    }
  }

  /// Merges two LeaseMaps, optionally sorts them

  Map<String, List<String>> mergeLeaseMaps(
      Map<String, List<String>> leaseMapInput,
      Map<String, List<String>> leaseMapMerge) {
    try {
      printMsg("Merging....");
      List<String> leaseListInput =
          flattenLeaseMap(leaseMapInput, sort: g.argResults['sort']);
      List<String> leaseListMerge =
          flattenLeaseMap(leaseMapMerge, sort: g.argResults['sort']);

      //This if statement determines which list is filtered for duplicates.
      //Duplicates in the argument for addAll will be filtered out
      //by removeBadLeases if they are already contained in existing lease.
      //So the status -r determines which is existing leaseMap and which
      //leaseMap will be filtered
      if (g.argResults['replace-duplicates-in-merge-file']) {
        leaseListInput.addAll(leaseListMerge);
        return explodeLeaseList(leaseListInput);
      } else {
        //this is the default, keep existing merge contents if duplicate lease
        //component in both
        leaseListMerge.addAll(leaseListInput);
        return explodeLeaseList(leaseListMerge);
      }
    } on Exception {
      rethrow;
    }
  }

  /// Takes List created by flattenLeaseMap and returns LeaseMap

  Map<String, List<String>> explodeLeaseList(List<String> leaseList) {
    Map<String, List<String>> leaseMap = <String, List<String>>{
      g.lbMac: <String>[],
      g.lbHost: <String>[],
      g.lbIp: <String>[],
    };

    for (String eachLease in leaseList) {
      List<String> tmpLease = eachLease.split("|");
      leaseMap[g.lbIp]!.add(tmpLease[3]);
      leaseMap[g.lbMac]!.add(tmpLease[1]);
      leaseMap[g.lbHost]!.add(tmpLease[2]);
    }
    return leaseMap;
  }

  /// Converts LeaseMap to a LeaseList consisting of long strings, each string
  /// consisting of fields separated by |.
  ///  4 Fields in string: IP converted to a normalized number string,
  /// mac, host, and ip address. Strings are sorted on first field

  List<String> flattenLeaseMap(Map<String, List<String>> leaseMap,
      {bool sort = true}) {
    Ip ip = Ip();
    List<String> leaseList = <String>[];
    for (int i = 0; i < leaseMap[g.lbMac]!.length; i++) {
      leaseList.add("${ip.ipStrToNum(leaseMap[g.lbIp]![i]).toString()}|"
          "${leaseMap[g.lbMac]![i]}|"
          "${leaseMap[g.lbHost]![i]}|"
          "${leaseMap[g.lbIp]![i]}");
    }
    if (sort) leaseList.sort();
    return leaseList;
  }

  ///  Merge Lease Map with Map of A Second File (Merge File Target)
  /// Returns Lease Map of Merge
  Map<String, List<String>> mergeLeaseMapWithFile(
      Map<String, List<String>> inputFileLeaseMap, String mergeTargetPath) {
    Map<String, List<String>> mergeTargetLeaseMap = <String, List<String>>{
      g.lbMac: <String>[],
      g.lbHost: <String>[],
      g.lbIp: <String>[],
    };

    dynamic mergeTargetFileType =
        g.cliArgs.getFormatTypeOfFile(mergeTargetPath);

    String displayMergeFile = (g.verbose)
        ? p.canonicalize(mergeTargetPath)
        : p.basename(mergeTargetPath);

    printMsg("Scanning merge file $displayMergeFile...");
    mergeTargetLeaseMap = mergeLeaseMaps(
        inputFileLeaseMap,
        g.inputTypeCl[mergeTargetFileType]!.getLeaseMap(
            fileContents: File(mergeTargetPath).readAsStringSync()));

    /* Remove duplicate leases **/
    return g.validateLeases
        .removeBadLeases(mergeTargetLeaseMap, mergeTargetFileType);
  }
}
