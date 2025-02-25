// Copyright 2025 GeekVisit All rights reserved.
// Use of this source code is governed by the license in the LICENSE file.

import 'dart:convert';

import '../lib.dart';

import 'globals.dart' as g;

/// A class that handles JSON file operations for static leases.
///
/// This class extends the `FileType` class and provides methods to:
/// - Extract lease information from JSON file contents.
/// - Build JSON strings from lease information.
/// - Validate JSON file contents.
///
/// Methods:
/// - `getLeaseMap`: Extracts lease information from JSON file contents.
/// - `build`: Builds a JSON string from lease information.
/// - `isContentValid`: Validates the JSON file contents.
/// - `isJson`: Checks if a string is a valid JSON format.
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

    Map<String, List<String>> rawLeaseMap = <String, List<String>>{
      g.lbHost: <String>[],
      g.lbMac: <String>[],
      g.lbIp: <String>[],
    };
    try {
      List<String> valueList = <String>[];
      if (fileContents == "") {
        printMsg("Source file is empty or corrupt.", errMsg: true);
        return rawLeaseMap;
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
    } on FormatException catch (e) {
      printMsg("""
Unable to extract static leases from File, file may not be proper json format, $e""");
      return rawLeaseMap;
    } on Exception {
      rethrow;
    }
  }

  @override
  String buildOutFileContents(
    Map<String, List<String>?> leaseMap,
  ) {
    StringBuffer sbJson = StringBuffer();
    for (int i = 0; i < leaseMap[g.lbMac]!.length; i++) {
      if (sbJson.isNotEmpty) sbJson.write(',');

      sbJson.write('''
{ "host-name" : "${leaseMap[g.lbHost]![i]}", "mac-address" : "${this.reformatMacForType(leaseMap[g.lbMac]![i], fileType)}", "address" : "${leaseMap[g.lbIp]![i]}" }''');
    }
    return "[ ${sbJson.toString()} ]";
  }

  bool isContentValid({String fileContents = "", List<String>? fileLines}) {
    try {
      if (fileContents == "") {
        throw Exception(
            "         argument provided for json.isContentProvided");
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

      g.validateLeases
          .isLeaseMapListValid(leaseMap, g.fFormats.json.formatName);

      return true;
    } on FormatException {
      return false;
    }
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
