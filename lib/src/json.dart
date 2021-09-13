import 'dart:convert';
import 'dart:io';

import '../lib.dart';

import 'globals.dart' as g;

class Json extends FileType {
  @override
  String fileType = g.fFormats.json.formatName;

  Map<String, List<String>> getLeaseMap(
      {String fileContents = "",
      List<String>? fileLines,
      bool removeBadLeases = true}) {
    //
    // ignore: unused_local_variable
    String fileType = g.fFormats.json.formatName;
    //

    try {
      Map<String, List<String>> leaseMap = <String, List<String>>{};
      List<String> valueList = <String>[];
      if (fileContents == "") {
        throw Exception("Missing json fileContents for getLease");
      }

      List<dynamic> deviceList = JsonDecoder().convert(fileContents);

      //picks out host-name, mac-address and ip-address from deviceList->Map
      for (String key in <String>[g.lbMac, g.lbHost, g.lbIp]) {
        for (Map<String, dynamic> jsonLease in deviceList) {
          valueList.add(jsonLease[key]);
        }
        leaseMap[key] = valueList.toList();
        valueList.clear();
      }
      if (removeBadLeases) {
        return g.validateLeases
            .getValidLeaseMap(leaseMap, g.fFormats.json.formatName);
      } else {
        return leaseMap;
      }
    } on Exception {
      //   printMsg(e, errMsg: true);
      rethrow;
    }
  }

  String build(Map<String, List<String>?> deviceList, StringBuffer sbJson) {
    for (int i = 0; i < deviceList[g.lbHost]!.length; i++) {
      if (sbJson.isNotEmpty) sbJson.write(',');
      sbJson.write('''
{ "host-name" : "${deviceList[g.lbHost]![i]}", "mac-address" : "${deviceList[g.lbMac]![i]}", "address" : "${deviceList[g.lbIp]![i]}" }''');
    }
    return "[ ${sbJson.toString()} ]";
  }

  bool isContentValid({String fileContents = "", List<String>? fileLines}) {
    ValidateLeases.initialize();
    try {
      if (fileContents == "") {
        throw Exception("No argument provided for json.isContentProvided");
      }

      if (!isJson(fileContents)) {
        return false;
      }

      Map<String, List<String>> leaseMap =
          getLeaseMap(fileContents: fileContents, removeBadLeases: false);

      if (g.validateLeases
          .containsBadLeases(leaseMap, g.fFormats.json.formatName)) {
        return false;
      }

      g.validateLeases.validateLeaseList(leaseMap, g.fFormats.json.formatName);

      return true;
    } on FormatException {
      return false;
    }
  }

  String toCsv() {
    try {
      Csv csv = Csv();
      StringBuffer sbCsv = StringBuffer();
      Map<String, List<String>> deviceList =
          getLeaseMap(fileContents: getJsonFileContents());
      csv.build(deviceList, sbCsv);

      //csv.csvAddColumnNamesAndRows(deviceList, sbCsv);
      return sbCsv.toString();
    } on FormatException catch (e) {
      throw Exception("Badly Formatted Json File: $e");
    }
  }

  String toDdwrt() {
    Ddwrt ddwrt = Ddwrt();
    StringBuffer sbDdwrt = StringBuffer();
    Map<String, List<String>> deviceList =
        getLeaseMap(fileContents: getJsonFileContents());
    ddwrt.build(deviceList, sbDdwrt);
    return (sbDdwrt.toString());
  }

  String toOpenWrt() {
    OpenWrt openWrt = OpenWrt();

    StringBuffer sbOpenWrt = StringBuffer();
    Map<String, List<String>> deviceList =
        getLeaseMap(fileContents: getJsonFileContents());
    return openWrt.build(deviceList, sbOpenWrt);
  }

  String toMikroTik() {
    Mikrotik mikrotik = Mikrotik();
    StringBuffer sbMikrotik = StringBuffer();

    Map<String, List<String>> deviceList =
        getLeaseMap(fileContents: getJsonFileContents());

    return mikrotik.build(deviceList, sbMikrotik);
  }

  @override
  String toJson() {
    StringBuffer sbJson = StringBuffer();
    String inFileContents = File(g.inputFile).readAsStringSync();

    Map<String, List<String>> deviceList =
        getLeaseMap(fileContents: inFileContents);

    return build(deviceList, sbJson);
  }

  //Get contents of json file, or temporary json file if none given
  String getJsonFileContents([String jsonFilePath = 'tempJsonOutFilePath']) {
    //
    //
    //This defaults to the global temporary file path,
    //otherwise user defined path
    jsonFilePath = (jsonFilePath == "tempJsonOutFilePath")
        ? g.tempJsonOutFile.path
        : jsonFilePath;

    return File(jsonFilePath).readAsStringSync();
  }

  String toPfsense() {
    PfSense pfSense = PfSense();
    StringBuffer sbPfsense = StringBuffer();

    Map<String, List<String>> deviceList =
        getLeaseMap(fileContents: getJsonFileContents());

    return pfSense.build(deviceList, sbPfsense);
  }

  String toOpnsense() {
    OpnSense opnSense = OpnSense();
    StringBuffer sbOpnsense = StringBuffer();

    Map<String, List<String>> deviceList =
        getLeaseMap(fileContents: getJsonFileContents());

    return opnSense.build(deviceList, sbOpnsense);
  }

  bool isJson(String string) {
    try {
      JsonDecoder jsonDecoder = JsonDecoder();
      jsonDecoder.convert(string);
      return true;
    } on FormatException {
      return false;
    }
  }
}
