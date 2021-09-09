import 'dart:io';

import 'package:path/path.dart' as p;
import 'globals.dart' as g;

import 'src.dart';

class Converter {
  // ignore: slash_for_doc_comments
  /** Main loop - process each file argument */

  String outPath = "";

  void convertFileList(List<String> arguments) {
    try {
      initialize(arguments);
      g.inputFileList = g.cliArgs.getInputFileList(g.argResults.rest);
      for (String eachFilePath in g.inputFileList) {
        g.inputFile = eachFilePath;
        toJson();
        toOutput();
      }
    } on Exception {
      rethrow;
    }
  }

  void toJson() {
    try {
      Json json = Json();
      setBaseName();

      g.inputType = g.cliArgs.getInputType();
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
            saveOutFile(json.toCsv());
            csv.isFileValid(outPath);
            printCompletedAll(g.fFormats.csv.formatName);
            break;

          case 'd':
            Ddwrt ddwrt = Ddwrt();
            setOutPath(g.fFormats.ddwrt.outputExt);
            saveOutFile(json.toDdwrt());
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
            saveOutFile(json.toMikroTik());
            //outPath may change if needs saveFile needs to avoid overwriting
            mikrotik.isFileValid(outPath);
            printCompletedAll(g.fFormats.mikrotik.formatName);
            break;
/* //TODO:  don't think i need this any more - test 
          case 'M':
            printMsg("""
Missing required -g (generated type) option. 
Run uprt without arguments to see usage.""",
                errMsg: true);
            cleanUp();
            break;
*/
          case 'n':
            OpnSense opnSense = OpnSense();
            setOutPath(g.fFormats.opnsense.outputExt);
            saveOutFile(json.toOpnsense());
            opnSense.isFileValid(outPath);
            printCompletedAll(g.fFormats.opnsense.formatName);

            break;

          case 'o':
            OpenWrt openWrt = OpenWrt();
            setOutPath(g.fFormats.openwrt.outputExt);
            saveOutFile(json.toOpenWrt());
            openWrt.isFileValid(outPath);
            printCompletedAll(g.fFormats.openwrt.formatName);
            break;

          case 'p':
            PfSense pfSense = PfSense();
            setOutPath(g.fFormats.json.outputExt);
            saveOutFile(json.toPfsense());
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

  void saveOutFile(String outContents) {
    //outPath may change if needs saveFile needs to avoid overwriting
    outPath =
        saveFile(outContents, outPath, overWrite: g.argResults['write-over']);
  }

// ignore: slash_for_doc_comments
/** Build output path for generated filed given the output extension */
  void setOutPath(String outputExt) {
    outPath =
        p.canonicalize("${File(p.join(g.dirOut, g.baseName)).absolute.path}."
            "$outputExt");
  }

  void printCompletedAll(String fileType) {
    String displaySourceFile =
        (g.argResults['verbose']) ? g.inputFile : p.basename(g.inputFile);
    String displayTargetFile =
        (g.argResults['verbose']) ? outPath : p.basename(outPath);

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

    printMsg("${g.newL}uprt converting ...", onlyIfVerbose: true);
    if (g.logPath != "") {
      String logMessage =
          '''${meta['name']} (${meta['version']} running on ${Platform.operatingSystem} ${Platform.operatingSystemVersion} Locale: ${Platform.localeName})${g.newL}''';

      printMsg(logMessage, logOnly: true);
    }
  }

  static void cleanUp() {
    try {
      if (g.tempDir.existsSync()) g.tempDir.deleteSync(recursive: true);
    } on Exception {
      rethrow;
    }
  }

  void setBaseName() {
    g.baseName = (g.argResults['base-name'] == "")
        ? p.basenameWithoutExtension(g.inputFile)
        : g.argResults['base-name'];
  }
} //end Class
