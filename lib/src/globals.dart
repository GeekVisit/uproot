import 'dart:io';

import 'package:path/path.dart' as p;

import 'cli_args.dart';

import 'file_ops.dart';
import 'validate_leases.dart';

Directory tempDir = Directory.systemTemp.createTempSync("uprt_");
File tempJsonOutFile = getTmpIntermedConvFile("tmpJsonFile");
String dirOut = argResults['directory-out'];
//Output directory with basename attached
String basePath = File(p.join(dirOut, argResults['base-name'])).absolute.path;

String inputType = "j";

Map<String, String> outputPathNames = <String, String>{
  "${fFormats.openwrt.formatName}": "$basePath.${fFormats.openwrt.outputExt}",
  "${fFormats.ddwrt.formatName}": "$basePath.${fFormats.ddwrt.outputExt}",
  "${fFormats.mikrotik.formatName}": "$basePath.${fFormats.mikrotik.outputExt}",
  "${fFormats.json.formatName}": "$basePath.${fFormats.json.outputExt}",
  "${fFormats.csv.formatName}": "$basePath.${fFormats.csv.outputExt}",
  "${fFormats.pfsense.formatName}":
      "$basePath-pfs.${fFormats.pfsense.outputExt}",
  "${fFormats.opnsense.formatName}":
      "$basePath-opn.${fFormats.opnsense.outputExt}",
};

Map<String, String> typeOptionToName = <String, String>{
  fFormats.csv.abbrev: fFormats.csv.formatName,
  fFormats.ddwrt.abbrev: fFormats.ddwrt.formatName,
  fFormats.json.abbrev: fFormats.json.formatName,
  fFormats.mikrotik.abbrev: fFormats.mikrotik.formatName,
  fFormats.openwrt.abbrev: fFormats.openwrt.formatName,
  fFormats.pfsense.abbrev: fFormats.pfsense.formatName,
  fFormats.opnsense.abbrev: fFormats.opnsense.formatName
};

Map<String, String> extToTypes = <String, String>{
  fFormats.csv.outputExt: fFormats.csv.abbrev,
  fFormats.ddwrt.outputExt: fFormats.ddwrt.abbrev,
  fFormats.json.outputExt: fFormats.json.abbrev,
  fFormats.mikrotik.outputExt: fFormats.mikrotik.abbrev,
  fFormats.openwrt.outputExt: fFormats.openwrt.abbrev,
  fFormats.pfsense.outputExt: fFormats.pfsense.abbrev,
  fFormats.opnsense.outputExt: fFormats.opnsense.abbrev
};

enum fFormats {
  csv,
  ddwrt,
  json,
  mikrotik,
  openwrt,
  pfsense,
  opnsense,
}

extension FileFormatProps on fFormats {
  static const Map<dynamic, String> abbrevs = <dynamic, String>{
    fFormats.csv: 'c',
    fFormats.ddwrt: 'd',
    fFormats.json: 'j',
    fFormats.mikrotik: 'm',
    fFormats.opnsense: 'n',
    fFormats.openwrt: 'o',
    fFormats.pfsense: 'p',
  };

  static const Map<dynamic, String> outputExts = <dynamic, String>{
    fFormats.csv: 'csv',
    fFormats.ddwrt: 'ddwrt',
    fFormats.json: 'json',
    fFormats.mikrotik: 'rsc',
    fFormats.opnsense: 'xml',
    fFormats.openwrt: 'openwrt',
    fFormats.pfsense: 'xml',
  };

  static const Map<dynamic, String> formatNames = <dynamic, String>{
    fFormats.csv: 'Csv',
    fFormats.ddwrt: 'DD-WRT',
    fFormats.json: 'Json',
    fFormats.mikrotik: 'Mikrotik',
    fFormats.opnsense: 'OPNsense',
    fFormats.openwrt: 'OpenWrt',
    fFormats.pfsense: 'pfSense',
  };

  static final Map<dynamic, String> outPutPathName = <dynamic, String>{
    fFormats.csv: "$basePath.${fFormats.csv.outputExt}",
    fFormats.ddwrt: "$basePath.${fFormats.ddwrt.outputExt}",
    fFormats.json: "$basePath.${fFormats.json.outputExt}",
    fFormats.mikrotik: "$basePath.${fFormats.mikrotik.outputExt}",
    fFormats.openwrt: "$basePath.${fFormats.openwrt.outputExt}",
    fFormats.opnsense: "$basePath.${fFormats.opnsense.outputExt}",
    fFormats.pfsense: "$basePath.${fFormats.pfsense.outputExt}",
  };

  String get abbrev => abbrevs[this]!;
  String get outputExt => outputExts[this]!;
  String get formatName => formatNames[this]!;
}

Map<String, String> conversionTypes = <String, String>{
  fFormats.csv.abbrev: fFormats.csv.formatName,
  fFormats.ddwrt.abbrev: fFormats.ddwrt.formatName,
  fFormats.json.abbrev: fFormats.json.formatName,
  fFormats.mikrotik.abbrev: fFormats.mikrotik.formatName,
  fFormats.openwrt.abbrev: fFormats.openwrt.formatName,
  fFormats.opnsense.abbrev: fFormats.opnsense.formatName,
  fFormats.pfsense.abbrev: fFormats.pfsense.formatName,
};

ValidateLeases validateLeases = ValidateLeases();

const String lbMac = 'mac-address';
const String lbHost = 'host-name';
const String lbIp = 'address';

CliArgs cliArgs = CliArgs();
dynamic argResults = "";

String logPath = "";

bool testRun = false;

String newL = (Platform.isWindows) ? "\r\n" : newL = "\n";

// ignore: avoid_classes_with_only_static_members
class MetaCheck {
  static int match = 0;
  static int mismatch = 1;
  static int runningAsBinary = 2;
}
