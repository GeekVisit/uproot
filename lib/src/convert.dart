import 'dart:io';

import 'package:path/path.dart' as p;

import 'globals.dart';
import 'pfsense.dart';
import 'src.dart';

void upRoot(List<String> arguments) {
  try {
    argResults = cliArgs.getArgs(arguments);
    cliArgs.checkArgs();
    initialize();
    convertToJson();
    convertToOutput();
  } on Exception {
    rethrow;
  }
}

void convertToJson() {
  try {
    Json json = Json();

    inputType = cliArgs.getInputType();
    printMsg("Converting Input File to Json temporary file..",
        onlyIfVerbose: true);
    switch (inputType) {
      case 'c':
        Csv csv = Csv();
        csv.isFileValid(File(argResults['input-file']).absolute.path);
        saveOutFile(csv.toJson(), tempJsonOutFile.path);
        printCompletedTmpJson("Csv");
        break;

      case 'd':
        Ddwrt ddwrt = Ddwrt();
        ddwrt.isFileValid(File(argResults['input-file']).absolute.path);
        saveOutFile(ddwrt.toJson(), tempJsonOutFile.path);
        printCompletedTmpJson("Ddwrt");
        break;

      case 'j':
        File inFile = File(File(argResults['input-file']).absolute.path);
        try {
          json.isFileValid(File(argResults['input-file']).absolute.path);
          inFile.copySync(tempJsonOutFile.path);
        } on FileSystemException {
          tempDir = Directory.systemTemp.createTempSync("uprt_");
          tempJsonOutFile = getTmpIntermedConvFile("tmpJsonFile");
          inFile.copySync(tempJsonOutFile.path);
        }
        printCompletedTmpJson("json");
        break;

      case 'm':
        Mikrotik mikrotik = Mikrotik();
        mikrotik.isFileValid(File(argResults['input-file']).absolute.path);
        saveOutFile(mikrotik.toJson(), tempJsonOutFile.path);
        printCompletedTmpJson("Mikrotik");
        break;

      case 'n':
        OpnSense opnSense = OpnSense();
        opnSense.isFileValid(File(argResults['input-file']).absolute.path);
        saveOutFile(opnSense.toJson(), tempJsonOutFile.path);
        printCompletedTmpJson("Opnsense");
        break;

      case 'o':
        OpenWrt openWrt = OpenWrt();
        openWrt.isFileValid(File(argResults['input-file']).absolute.path);
        saveOutFile(openWrt.toJson(), tempJsonOutFile.path);
        printCompletedTmpJson("OpenWrt");
        break;

      case 'p':
        PfSense pfSense = PfSense();
        pfSense.isFileValid(File(argResults['input-file']).absolute.path);
        saveOutFile(pfSense.toJson(), tempJsonOutFile.path);
        printCompletedTmpJson("Pfsense");
        break;

      default:
        printMsg("Incorrect input type: $inputType}", errMsg: true);
        sleep(Duration(seconds: 1));
        cliArgs.displayHelp();
        exit(1);
    }
  } on Exception {
    rethrow;
  }
}

void convertToOutput() {
  try {
    Json json = Json();
    String outFile;
    printMsg("Converting Temporary json File to Output Formats..",
        onlyIfVerbose: true);

    /**  split type argument regardless of comma separator
    */
    List<String> types =
        getArgListOfMultipleOption(argResults['generate-type']);

    for (dynamic each_type in types) {
      switch (each_type) {
        case 'c':
          Csv csv = Csv();
          outFile = saveOutFile(
              json.toCsv(), outputPathNames[fFormats.csv.formatName]!,
              overWrite: argResults['write-over']);
          csv.isFileValid(outFile);
          printCompletedAll(fFormats.csv.formatName);
          break;

        case 'd':
          Ddwrt ddwrt = Ddwrt();
          outFile = saveOutFile(
              json.toDdwrt(), outputPathNames[fFormats.ddwrt.formatName]!,
              overWrite: argResults['write-over']);
          ddwrt.isFileValid(outFile);

          printCompletedAll(fFormats.ddwrt.formatName);
          break;

        case 'j':
          tempJsonOutFile.copySync(outputPathNames[fFormats.json.formatName]!);
          printCompletedAll(fFormats.json.formatName);
          break;

        case 'm':
          Mikrotik mikrotik = Mikrotik();
          outFile = saveOutFile(
              json.toMikroTik(), outputPathNames[fFormats.mikrotik.formatName]!,
              overWrite: argResults['write-over']);
          mikrotik.isFileValid(outFile);
          printCompletedAll(fFormats.mikrotik.formatName);
          break;

        case 'M':
          printMsg("""
Missing required -g (generated type) option. Run uprt without arguments to see usage.""",
              errMsg: true);
          cleanUp();
          break;

        case 'n':
          OpnSense opnSense = OpnSense();

          outFile = saveOutFile(
              json.toOpnsense(), outputPathNames[fFormats.opnsense.formatName]!,
              overWrite: argResults['write-over']);

          opnSense.isFileValid(outFile);
          printCompletedAll(fFormats.opnsense.formatName);

          break;

        case 'o':
          OpenWrt openWrt = OpenWrt();

          outFile = saveOutFile(
              json.toOpenWrt(), outputPathNames[fFormats.openwrt.formatName]!,
              overWrite: argResults['write-over']);

          openWrt.isFileValid(outFile);
          printCompletedAll(fFormats.openwrt.formatName);
          break;

        case 'p':
          PfSense pfSense = PfSense();

          outFile = saveOutFile(
              json.toPfsense(), outputPathNames[fFormats.pfsense.formatName]!,
              overWrite: argResults['write-over']);

          pfSense.isFileValid(outFile);
          printCompletedAll(fFormats.pfsense.formatName);

          break;

        default:
          printMsg("Incorrect Output type: $each_type.", errMsg: true);
          sleep(Duration(seconds: 1));
          cliArgs.displayHelp();
          exit(1);
      }
    }
  } on Exception catch (e) {
    printMsg(e, errMsg: true);
    rethrow;
  }
}

List<String> getArgListOfMultipleOption(dynamic argOption) {
  List<String> types = (argOption[0].length > 1)
      ? argOption[0].split(RegExp(r"b*"))
      : argOption[0].split(",");
  return types;
}

void printCompletedAll(String fileType) {
  printMsg("""
${typeOptionToName[inputType]} to $fileType is completed.""");
}

void printCompletedTmpJson(String fileType) {
  printMsg(
      """$fileType to temporary Json ${p.basename(tempJsonOutFile.path)} is completed.""",
      onlyIfVerbose: true);
}

void initialize() {
  printMsg("${newL}uprt converting ...", onlyIfVerbose: true);
  if (logPath != "") {
    String logMessage =
        '''${meta.name} (${meta.version} running on ${Platform.operatingSystem} ${Platform.operatingSystemVersion} Locale: ${Platform.localeName})$newL''';

    printMsg(logMessage, logOnly: true);
  }
}

void cleanUp() {
  try {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  } on Exception {
    rethrow;
  }
}
