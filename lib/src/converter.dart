import 'dart:io';

import 'package:path/path.dart' as p;
import 'globals.dart' as g;

import 'src.dart';

class Converter {
  // ignore: slash_for_doc_comments
  /** Main loop - process each file argument */

  String outPath = "";
  List<String> outputFilesSaved = <String>[];

  // ignore: slash_for_doc_comments
  /** Main loop to convert all files on command line */
  void convertFileList(List<String> arguments) {
    try {
      initialize(arguments);
      g.inputFileList = g.cliArgs.getInputFileList(g.argResults.rest);


      
      for (String eachFilePath in g.inputFileList) {
        setInputFile(eachFilePath);
        toJson();
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

      g.inputType = g.cliArgs.getInputType();
    } on Exception {
      return;
    }
  }

  void toJson() {
    try {
      Json json = Json();
      printMsg("Converting Input File to Json temporary file..",
          onlyIfVerbose: true);
      switch (g.inputType) {
        case 'c':
          Csv csv = Csv();
          csv.isFileValid(File(g.inputFile).absolute.path);
          saveFile(csv.toJson(), g.tempJsonOutFile.path);
          printCompletedTmpJson("Csv");
          break;

        case 'd':
          Ddwrt ddwrt = Ddwrt();
          ddwrt.isFileValid(File(g.inputFile).absolute.path);
          saveFile(ddwrt.toJson(), g.tempJsonOutFile.path);
          printCompletedTmpJson("Ddwrt");
          break;

        case 'j':
          File inFile = File(File(g.inputFile).absolute.path);
          try {
            json.isFileValid(File(g.inputFile).absolute.path);
            inFile.copySync(g.tempJsonOutFile.path);
          } on FileSystemException {
            g.tempDir = Directory.systemTemp.createTempSync("uprt_");
            g.tempJsonOutFile = getTmpIntermedConvFile("tmpJsonFile");
            inFile.copySync(g.tempJsonOutFile.path);
          }
          printCompletedTmpJson("json");
          break;

        case 'm':
          Mikrotik mikrotik = Mikrotik();
          mikrotik.isFileValid(File(g.inputFile).absolute.path);
          saveFile(mikrotik.toJson(), g.tempJsonOutFile.path);
          printCompletedTmpJson("Mikrotik");
          break;

        case 'n':
          OpnSense opnSense = OpnSense();
          opnSense.isFileValid(File(g.inputFile).absolute.path);
          saveFile(opnSense.toJson(), g.tempJsonOutFile.path);
          printCompletedTmpJson("Opnsense");
          break;

        case 'o':
          OpenWrt openWrt = OpenWrt();
          openWrt.isFileValid(File(g.inputFile).absolute.path);
          saveFile(openWrt.toJson(), g.tempJsonOutFile.path);
          printCompletedTmpJson("OpenWrt");
          break;

        case 'p':
          PfSense pfSense = PfSense();
          pfSense.isFileValid(File(g.inputFile).absolute.path);
          saveFile(pfSense.toJson(), g.tempJsonOutFile.path);
          printCompletedTmpJson("Pfsense");
          break;

        default:
          printMsg("Incorrect input type: ${g.inputType}", errMsg: true);
          sleep(Duration(seconds: 1));
          g.cliArgs.displayHelp();
          exit(1);
      }
    } on Exception {
      rethrow;
    }
  }

  void toOutput() {
    try {
      Json json = Json();

      printMsg("Converting Temporary json File to Output Formats..",
          onlyIfVerbose: true);

      /**  split type argument regardless of comma separator
    */

      List<String> types =
          g.cliArgs.getArgListOfMultipleOptions(g.argResults['generate-type']);

      for (dynamic each_type in types) {
        switch (each_type) {
          case 'c':
            Csv csv = Csv();
            setOutPath(g.fFormats.csv.outputExt);
            saveOutPath(json.toCsv());
            csv.isFileValid(outPath);
            printCompletedAll(g.fFormats.csv.formatName);
            break;

          case 'd':
            Ddwrt ddwrt = Ddwrt();
            setOutPath(g.fFormats.ddwrt.outputExt);
            saveOutPath(json.toDdwrt());
            ddwrt.isFileValid(outPath);
            printCompletedAll(g.fFormats.ddwrt.formatName);
            break;

          case 'j':
            setOutPath(g.fFormats.json.outputExt);
            //outPath may change if needs saveFile needs to avoid overwriting
            g.tempJsonOutFile.copySync(outPath);
            printCompletedAll(g.fFormats.json.formatName);
            break;

          case 'm':
            Mikrotik mikrotik = Mikrotik();
            setOutPath(g.fFormats.mikrotik.outputExt);
            saveOutPath(json.toMikroTik());
            //outPath may change if needs saveFile needs to avoid overwriting
            mikrotik.isFileValid(outPath);
            printCompletedAll(g.fFormats.mikrotik.formatName);
            break;

          case 'n':
            OpnSense opnSense = OpnSense();
            setOutPath("-opn.${g.fFormats.opnsense.outputExt}");
            saveOutPath(json.toOpnsense());
            opnSense.isFileValid(outPath);
            printCompletedAll(g.fFormats.opnsense.formatName);

            break;

          case 'o':
            OpenWrt openWrt = OpenWrt();
            setOutPath(g.fFormats.openwrt.outputExt);
            saveOutPath(json.toOpenWrt());
            openWrt.isFileValid(outPath);
            printCompletedAll(g.fFormats.openwrt.formatName);
            break;

          case 'p':
            PfSense pfSense = PfSense();
            setOutPath("-pfs.${g.fFormats.pfsense.outputExt}");
            saveOutPath(json.toPfsense());
            pfSense.isFileValid(outPath);
            printCompletedAll(g.fFormats.pfsense.formatName);

            break;

          default:
            printMsg("Incorrect Output type: $each_type.", errMsg: true);
            sleep(Duration(seconds: 1));
            g.cliArgs.displayHelp();
            exit(1);
        }
      }
    } on Exception catch (e) {
      printMsg(e, errMsg: true);
      rethrow;
    }
  }

  // ignore: slash_for_doc_comments
  /** Saves Converted Output file */
  void saveOutPath(String outContents) {
    /** Don't save over files previously saved in same run if happen to have
     *  same name, overrides write-over command line option*/
    bool overWrite = (outputFilesSaved.contains(outPath))
        ? false
        : g.argResults['write-over'];

    outPath = saveFile(outContents, outPath, overWrite: overWrite);
    outputFilesSaved.add(outPath);
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

  void printCompletedAll(String fileType) {
    String displaySourceFile = (g.argResults['verbose'])
        ? p.canonicalize(g.inputFile)
        : p.basename(g.inputFile);
    String displayTargetFile = (g.argResults['verbose'])
        ? p.canonicalize(outPath)
        : p.basename(outPath);

    printMsg("""
$displaySourceFile =>> $displayTargetFile (${g.typeOptionToName[g.inputType]} => $fileType) is completed.""");
  }

  void printCompletedTmpJson(String fileType) {
    printMsg(
        """$fileType to temporary Json ${p.basename(g.tempJsonOutFile.path)} is completed.""",
        onlyIfVerbose: true);
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
    } on Exception {
      rethrow;
    }
  }
} //end Class
