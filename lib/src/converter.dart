import 'dart:io';

import 'package:path/path.dart' as p;
import 'globals.dart' as g;

import 'src.dart';

class Converter {
  // ignore: slash_for_doc_comments
  /** Main loop - process each file argument */

  String outPath = "";

  // ignore: slash_for_doc_comments
  /** Output files that have been saved to prevent overwriting */
  List<String> outputFilesSaved = <String>[];

  // ignore: slash_for_doc_comments
  /** Main loop to convert all files on command line */
  void convertFileList(List<String> arguments) {
    try {
      initialize(arguments);
      g.inputFileList = g.cliArgs.getInputFileList(g.argResults.rest);

      for (String eachFilePath in g.inputFileList) {
        setInputFile(eachFilePath);
        printMsg("Converting ${p.basename(eachFilePath)}...");

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
            saveAndValidateOutFile(toCsv(), Csv(), g.fFormats.csv.abbrev,
                g.fFormats.csv.outputExt);
            break;

          case 'd':
            saveAndValidateOutFile(toDdwrt(), Ddwrt(), g.fFormats.ddwrt.abbrev,
                g.fFormats.ddwrt.outputExt);
            break;

          case 'j':
            saveAndValidateOutFile(toJson(), Json(), g.fFormats.json.abbrev,
                g.fFormats.json.outputExt);
            break;

          case 'm':
            saveAndValidateOutFile(toMikroTik(), Mikrotik(),
                g.fFormats.mikrotik.abbrev, g.fFormats.mikrotik.outputExt);
            break;

          case 'n':
            saveAndValidateOutFile(
                toOpnSense(),
                OpnSense(),
                g.fFormats.opnsense.abbrev,
                "-opn.${g.fFormats.opnsense.outputExt}");

            break;

          case 'o':
            saveAndValidateOutFile(toOpenWrt(), OpenWrt(),
                g.fFormats.openwrt.abbrev, g.fFormats.openwrt.outputExt);
            break;

          case 'p':
            saveAndValidateOutFile(
                toPfsense(),
                PfSense(),
                g.fFormats.pfsense.abbrev,
                "-pfs.${g.fFormats.opnsense.outputExt}");

            break;

          default:
            printMsg("Incorrect Output type: $eachOutputType.", errMsg: true);
            sleep(Duration(seconds: 1));
            g.cliArgs.displayHelp();
            exit(1);
        }
      }
    } on Exception catch (e) {
      if (e.toString().contains("is invalid format")) {
        printMsg(e);
        if (g.testRun) rethrow;
        return;
      }
      rethrow;
    }
  }

// ignore: slash_for_doc_comments
/** Save converted contents to outFile path and check if valid */
  void saveAndValidateOutFile(String fileContents, FileType outputClass,
      String outputFormatName, String outputExt) {
    try {
      setOutPath(outputExt);
      printCompletedAll(outputFormatName,
          success: (fileContents != "" &&
              outputClass.isContentValid(fileContents: fileContents) &&
              saveToOutPath(fileContents)));
    } on Exception {
      rethrow;
    }
  }

  // ignore: slash_for_doc_comments
  /** Saves Converted Output file */
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

// ignore: slash_for_doc_comments
/** Builds output path for generated filed given the output extension */
  void setOutPath(String outputExt) {
    // Sets output directory to g.dirname or if not specified then input dir
    g.dirOut = (g.argResults['directory-out'] == null ||
            g.argResults['directory-out'] == "")
        ? p.dirname(g.inputFile)
        : g.argResults['directory-out'];

    if (!Directory(g.dirOut).existsSync()) {
      throw Exception("Output directory ${g.dirOut} does not exist. ");
    }

    outputExt = (outputExt.contains(".")) ? outputExt : ".$outputExt";

    outPath =
        p.canonicalize("${File(p.join(g.dirOut, g.baseName)).absolute.path}"
            "$outputExt");
  }

  void printCompletedAll(String fileType, {bool success = true}) {
    String displaySourceFile = (g.argResults['verbose'])
        ? p.canonicalize(g.inputFile)
        : p.basename(g.inputFile);
    String displayTargetFile = (g.argResults['verbose'])
        ? p.canonicalize(outPath)
        : p.basename(outPath);
    String successResult = (success) ? "successful" : "failed";

    printMsg("""
$displaySourceFile =>>> $displayTargetFile (${g.typeOptionToName[g.inputType]} => ${g.typeOptionToName[fileType]} $successResult).""");
  }


// ignore: slash_for_doc_comments
/** Initializes programs - does some validation of arguments 
 * and meta, and sets up log */

  void initialize(List<String> arguments) {
    MetaUpdate("pubspec.yaml").verifyCodeHasUpdatedMeta();

    g.argResults = g.cliArgs.getArgs(arguments);
    g.cliArgs.checkArgs();
    setLogPath();

    printMsg("${g.newL}uprt converting ...", onlyIfVerbose: true);
    if (g.logPath != "") {
      String logMessage =
          '''${meta['name']} (${meta['version']} running on ${Platform.operatingSystem} ${Platform.operatingSystemVersion} Locale: ${Platform.localeName})${g.newL}''';

      printMsg(logMessage, logOnly: true);
    }
  }

  // ignore: slash_for_doc_comments
  /**  Set log-file-path to system temp folder if option set */
  void setLogPath() {
    g.logPath = (g.argResults['log'] &&
            isStringAValidFilePath(g.argResults['log-file-path']))
        ? g.argResults['log-file-path']
        : '${p.join(Directory.systemTemp.path, "uprt.log")}';
  }

  // ignore: slash_for_doc_comments
  /** Post Conversion Cleanup */
  static void cleanUp() {
    try {
      if (g.tempDir.existsSync()) g.tempDir.deleteSync(recursive: true);
    } on Exception catch (e) {
      print(e);
    }
  }

// ignore: slash_for_doc_comments
  /** Gets the temporary LeaseMap from json file and Merge if Option Given 
  */
  Map<String, List<String>> getSourceLeaseMap() {
    Map<String, List<String>> inputLeaseMap = g.inputTypeCl[g.inputType]!
        .getLeaseMap(
            fileContents: getFileContents(g.inputFile),
            fileLines: File(g.inputFile).readAsLinesSync(),
            removeBadLeases: true);

    return (g.argResults['merge'] != null)
        ? <String, List<String>>{
            ...mergeLeaseMapWithFile(
                inputLeaseMap, getGoodPath(g.argResults['merge']))
          }
        : inputLeaseMap;
  }

// ignore: slash_for_doc_comments
/**  Builds Csv String from input File and Merge File */
  String toCsv() {
    return Csv().build(getSourceLeaseMap());
  }

// ignore: slash_for_doc_comments
/**  Builds Ddwrt String from input File and Merge File */
  String toDdwrt() {
    return Ddwrt().build(getSourceLeaseMap());
  }
// ignore: slash_for_doc_comments
/**  Builds Json String from input & merge file */

  String toJson() {
    return Json().build(getSourceLeaseMap());
  }

// ignore: slash_for_doc_comments
/**  Builds OpenWrt String from input and merge File */
  String toOpenWrt() {
    return OpenWrt().build(getSourceLeaseMap());
  }

// ignore: slash_for_doc_comments
/**  Builds Mikrotik String from input and merge File */
  String toMikroTik() {
    return Mikrotik().build(getSourceLeaseMap());
  }

// ignore: slash_for_doc_comments
/**  Builds OpnSense from input and merge File */

  String toPfsense() {
    return PfSense().build(getSourceLeaseMap());
  }

// ignore: slash_for_doc_comments
/**  Builds OpnSense String from OpnSense File and Merge File */
  String toOpnSense() {
    return OpnSense().build(getSourceLeaseMap());
  }

// ignore: slash_for_doc_comments
/**  Merges two LeaseMaps, optionally sorts them 
 * Second LeaseMap takes precedence  */

  Map<String, List<String>> mergeLeaseMaps(
      Map<String, List<String>> leaseMap1, Map<String, List<String>> leaseMap2,
      {bool sort = true}) {
    try {
      List<String> leaseList1 = flattenLeaseMap(leaseMap1, sort: sort);
      List<String> leaseList2 = flattenLeaseMap(leaseMap2, sort: sort);
      leaseList1.addAll(leaseList2);
      if (sort) leaseList1.sort();
      return explodeLeaseList(leaseList1);
    } on Exception {
      rethrow;
    }
  }

// ignore: slash_for_doc_comments
/** Takes List created by flattenLeaseMap and returns LeaseMap  */

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

// ignore: slash_for_doc_comments
/** Converts LeaseMap to a LeaseList consisting of long strings, each string 
 * consisting of fields separated by |. 
 * 4 Fields in string: IP converted to a normalized number string, mac, host, 
 * and ip address. Strings are sorted on first field */
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

// ignore: slash_for_doc_comments
/** Merge Lease Map with Map of A Second File (Merge File Target)
   * In case of conflict of Macs or host name, the lease with the lesser ip 
   * controls, if same ip, then the one in the mergeTarget file 
   * is replaced with 
   * the lease for that ip in the input file
   * 
   * Returns Lease Map of Merge
   */
  Map<String, List<String>> mergeLeaseMapWithFile(
      Map<String, List<String>> inputFileLeaseMap, String mergeTargetPath) {
    Map<String, List<String>> mergeTargetLeaseMap = <String, List<String>>{
      g.lbMac: <String>[],
      g.lbHost: <String>[],
      g.lbIp: <String>[],
    };

    dynamic mergeTargetFileType =
        g.typeOptionToName[g.cliArgs.getFormatTypeOfFile(mergeTargetPath)];

    printMsg("Processing merge file $mergeTargetPath ...");
    mergeTargetLeaseMap = mergeLeaseMaps(
        inputFileLeaseMap,
        g.inputTypeCl[mergeTargetFileType]!.getLeaseMap(
            fileContents: File(mergeTargetPath).readAsStringSync()));

    /* Remove duplicate lease **/
    return validateLeases.removeBadLeases(
        mergeTargetLeaseMap, mergeTargetFileType);
  }
}
