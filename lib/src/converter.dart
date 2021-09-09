import 'dart:io';

import 'package:path/path.dart' as p;
import 'globals.dart' as g;

import 'src.dart';

class Converter {
  // ignore: slash_for_doc_comments
  /** Main loop - process each file argument */
  void convertAll(List<String> arguments) {
    try {
      initialize(arguments);
      for (String eachFilePath
          in g.cliArgs.getInputFileList(g.argResults.rest)) {
        g.inputFile = eachFilePath;
        setBaseName();
        toJson();
        toOutput();
      }
    } on Exception {
      rethrow;
    }
  }

  void setBaseName() {
    g.baseName = (g.argResults['base-name'] == "")
        ? p.basenameWithoutExtension(g.inputFile)
        : g.argResults['base-name'];
  }

  void toJson() {
    try {
      Json json = Json();

      g.inputFile = g.cliArgs.getInputType();
      printMsg("Converting Input File to Json temporary file..",
          onlyIfVerbose: true);
      switch (g.inputFile) {
        case 'c':
          Csv csv = Csv();
          csv.isFileValid(File(g.inputFile).absolute.path);
          saveOutFile(csv.toJson(), g.tempJsonOutFile.path);
          printCompletedTmpJson("Csv");
          break;

        case 'd':
          Ddwrt ddwrt = Ddwrt();
          ddwrt.isFileValid(File(g.inputFile).absolute.path);
          saveOutFile(ddwrt.toJson(), g.tempJsonOutFile.path);
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
          saveOutFile(mikrotik.toJson(), g.tempJsonOutFile.path);
          printCompletedTmpJson("Mikrotik");
          break;

        case 'n':
          OpnSense opnSense = OpnSense();
          opnSense.isFileValid(File(g.inputFile).absolute.path);
          saveOutFile(opnSense.toJson(), g.tempJsonOutFile.path);
          printCompletedTmpJson("Opnsense");
          break;

        case 'o':
          OpenWrt openWrt = OpenWrt();
          openWrt.isFileValid(File(g.inputFile).absolute.path);
          saveOutFile(openWrt.toJson(), g.tempJsonOutFile.path);
          printCompletedTmpJson("OpenWrt");
          break;

        case 'p':
          PfSense pfSense = PfSense();
          pfSense.isFileValid(File(g.inputFile).absolute.path);
          saveOutFile(pfSense.toJson(), g.tempJsonOutFile.path);
          printCompletedTmpJson("Pfsense");
          break;

        default:
          printMsg("Incorrect input type: ${g.inputFile}", errMsg: true);
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
      String outFile;
      String outPath = "";
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

            outPath = "${File(p.join(g.dirOut, g.baseName)).absolute.path}"
                "${g.fFormats.csv.outputExt}";

            outFile = saveOutFile(json.toCsv(), outPath,
                overWrite: g.argResults['write-over']);
            csv.isFileValid(outFile);
            printCompletedAll(g.fFormats.csv.formatName);
            break;

          case 'd':
            Ddwrt ddwrt = Ddwrt();
            outPath = "${File(p.join(g.dirOut, g.baseName)).absolute.path}"
                "${g.fFormats.ddwrt.outputExt}";
            outFile = saveOutFile(json.toDdwrt(), outPath,
                overWrite: g.argResults['write-over']);
            ddwrt.isFileValid(outFile);

            printCompletedAll(g.fFormats.ddwrt.formatName);
            break;

          case 'j':
            outPath = "${File(p.join(g.dirOut, g.baseName)).absolute.path}"
                "${g.fFormats.json.outputExt}";

            g.tempJsonOutFile.copySync(outPath);
            printCompletedAll(g.fFormats.json.formatName);
            break;

          case 'm':
            Mikrotik mikrotik = Mikrotik();
            outPath = "${File(p.join(g.dirOut, g.baseName)).absolute.path}"
                "${g.fFormats.mikrotik.outputExt}";
            outFile = saveOutFile(json.toMikroTik(), outPath,
                overWrite: g.argResults['write-over']);
            mikrotik.isFileValid(outFile);
            printCompletedAll(g.fFormats.mikrotik.formatName);
            break;

          case 'M':
            printMsg("""
Missing required -g (generated type) option. Run uprt without arguments to see usage.""",
                errMsg: true);
            cleanUp();
            break;

          case 'n':
            OpnSense opnSense = OpnSense();
            outPath = "${File(p.join(g.dirOut, g.baseName)).absolute.path}"
                "${g.fFormats.opnsense.outputExt}";
            outFile = saveOutFile(json.toOpnsense(), outPath,
                overWrite: g.argResults['write-over']);

            opnSense.isFileValid(outFile);
            printCompletedAll(g.fFormats.opnsense.formatName);

            break;

          case 'o':
            OpenWrt openWrt = OpenWrt();
            outPath = "${File(p.join(g.dirOut, g.baseName)).absolute.path}"
                "${g.fFormats.openwrt.outputExt}";
            outFile = saveOutFile(json.toOpenWrt(), outPath,
                overWrite: g.argResults['write-over']);

            openWrt.isFileValid(outFile);
            printCompletedAll(g.fFormats.openwrt.formatName);
            break;

          case 'p':
            PfSense pfSense = PfSense();
            outPath = "${File(p.join(g.dirOut, g.baseName)).absolute.path}"
                "${g.fFormats.pfsense.outputExt}";
            outFile = saveOutFile(json.toPfsense(), outPath,
                overWrite: g.argResults['write-over']);

            pfSense.isFileValid(outFile);
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

  void printCompletedAll(String fileType) {
    printMsg("""
${g.typeOptionToName[g.inputFile]} to $fileType is completed.""");
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
} //end Class