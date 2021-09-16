import 'dart:convert';

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
      Map<String, List<String>> rawLeaseMap = <String, List<String>>{};
      List<String> valueList = <String>[];
      if (fileContents == "") {
        throw Exception("Missing json fileContents for getLease");
      }

      List<dynamic> deviceList = JsonDecoder().convert(fileContents);

      //picks out host-name, mac-address and ip-address from deviceList->Map
      for (String key in <String>[g.lbMac, g.lbHost, g.lbIp]) {
        for (Map<String, dynamic> jsonLease in deviceList) {
          jsonLease[key] = (jsonLease[key] == null) ? "" : jsonLease[key];
          valueList.add(jsonLease[key]);
        }

        rawLeaseMap[key] = valueList.toList();
        valueList.clear();
      }
      if (removeBadLeases) {
        return g.validateLeases
            .removeBadLeases(rawLeaseMap, g.fFormats.json.formatName);
      } else {
        return rawLeaseMap;
      }
    } on Exception {
      //   printMsg(e, errMsg: true);
      rethrow;
    }
  }

  String build(
    Map<String, List<String>?> deviceList,
  ) {
    StringBuffer sbJson = StringBuffer();
    for (int i = 0; i < deviceList[g.lbMac]!.length; i++) {
      if (sbJson.isNotEmpty) sbJson.write(',');

      sbJson.write('''
{ "host-name" : "${deviceList[g.lbHost]![i]}", "mac-address" : "${deviceList[g.lbMac]![i]}", "address" : "${deviceList[g.lbIp]![i]}" }''');
    }
    return "[ ${sbJson.toString()} ]";
  }

  bool isContentValid({String fileContents = "", List<String>? fileLines}) {
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
    Map<String, List<String>> deviceList =
        getLeaseMap(fileContents: g.tempJsonOutFile.readAsStringSync());

    deviceList = Csv().mergeIfOpted(deviceList);
    return Csv().build(deviceList);
  }

  String toDdwrt() {
    Map<String, List<String>> deviceList =
        getLeaseMap(fileContents: g.tempJsonOutFile.readAsStringSync());
    deviceList = Ddwrt().mergeIfOpted(deviceList);

    return Ddwrt().build(deviceList);
  }

  // String toJsonMerge() {
  //   //needs to be worked on - WIP TODO:
  //   /String inFileContents = File(g.inputFile).readAsStringSync();

  //   Map<String, List<String>> deviceList =
  //       getLeaseMap(fileContents: inFileContents);

  //   if (fileType == "Json") {
  //     deviceList = mergeIfOpted(deviceList);
  //   }

  //   return !g.validateLeases.areAllLeaseMapValuesEmpty(deviceList)
  //       ? build(deviceList)
  //       : "";
  // }

  String toOpenWrt() {
    Map<String, List<String>> deviceList =
        getLeaseMap(fileContents: g.tempJsonOutFile.readAsStringSync());
    deviceList = OpenWrt().mergeIfOpted(deviceList);
    return OpenWrt().build(deviceList);
  }

  String toMikroTik() {
    Map<String, List<String>> deviceList =
        getLeaseMap(fileContents: g.tempJsonOutFile.readAsStringSync());
    deviceList = Mikrotik().mergeIfOpted(deviceList);
    return Mikrotik().build(deviceList);
  }

  String toPfsense() {
    Map<String, List<String>> deviceList =
        getLeaseMap(fileContents: g.tempJsonOutFile.readAsStringSync());
    deviceList = PfSense().mergeIfOpted(deviceList);
    return PfSense().build(deviceList);
  }

  String toOpnSense() {
    Map<String, List<String>> deviceList =
        getLeaseMap(fileContents: g.tempJsonOutFile.readAsStringSync());
    deviceList = OpnSense().mergeIfOpted(deviceList);
    return OpnSense().build(deviceList);
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
