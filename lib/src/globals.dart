// Copyright 2021 GeekVisit All rights reserved.
// Use of this source code is governed by the license that can be
// found in the LICENSE file.

import 'dart:io';
import '../lib.dart';

List<String> arguments = <String>[];

Directory tempDir = Directory.systemTemp.createTempSync("uprt_");

///Last message sent to printMsg, used in tests
String lastPrint = "";

String dirOut = argResults['directory-out'];

List<String> inputFileList = <String>[];
String inputFile = "";
String inputType = "j";
String baseName = "";
bool verbose = false;

Map<String, FileType> inputTypeCl = <String, FileType>{
  fFormats.csv.abbrev: Csv(),
  fFormats.ddwrt.abbrev: Ddwrt(),
  fFormats.json.abbrev: Json(),
  fFormats.mikrotik.abbrev: Mikrotik(),
  fFormats.openwrt.abbrev: OpenWrt(),
  fFormats.pfsense.abbrev: PfSense(),
  fFormats.opnsense.abbrev: OpnSense(),
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
  fFormats.csv.fileExt: fFormats.csv.abbrev,
  fFormats.ddwrt.fileExt: fFormats.ddwrt.abbrev,
  fFormats.json.fileExt: fFormats.json.abbrev,
  fFormats.mikrotik.fileExt: fFormats.mikrotik.abbrev,
  fFormats.openwrt.fileExt: fFormats.openwrt.abbrev,
  fFormats.pfsense.fileExt: fFormats.pfsense.abbrev,
  fFormats.opnsense.fileExt: fFormats.opnsense.abbrev
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

  static const Map<dynamic, String> fileExts = <dynamic, String>{
    fFormats.csv: '.csv',
    fFormats.ddwrt: '.ddwrt',
    fFormats.json: '.json',
    fFormats.mikrotik: '.rsc',
    fFormats.opnsense: '-opn.xml',
    fFormats.openwrt: '.openwrt',
    fFormats.pfsense: '-pfs.xml',
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

  String get abbrev => abbrevs[this]!;
  String get fileExt => fileExts[this]!;
  String get formatName => formatNames[this]!;
}

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
