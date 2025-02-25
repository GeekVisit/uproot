// Copyright 2025 GeekVisit All rights reserved.
// Use of this source code is governed by the license in the LICENSE file.

import 'dart:convert';

import '../lib.dart';
import 'globals.dart' as g;

/// A class that represents a CSV file type and provides methods to manipulate
/// and validate CSV file contents.
///
/// The `Csv` class extends the `FileType` class and provides methods to:
/// - Parse CSV file contents and convert them into a map of leases.
/// - Build a CSV string from a map of device lists.
/// - Validate the contents of a CSV file.
/// - Add column names and rows to a CSV string buffer.
///
/// The class assumes that the CSV file has three columns: host name, MAC address,
/// and IP address, in that order.
///
/// Constants:
/// - `hostIdx`: The index of the host name column.
/// - `macIdx`: The index of the MAC address column.
/// - `ipIdx`: The index of the IP address column.
///
/// Properties:
/// - `fileType`: The type of the file, which is set to the CSV format name.
///
/// Methods:
/// - `getLeaseMap`: Parses the CSV file contents and returns a map of leases.
/// - `build`: Builds a CSV string from a map of device lists.
/// - `isContentValid`: Validates the contents of a CSV file.
/// - `csvAddColumnNamesAndRows`: Adds column names and rows to a CSV string buffer.
class Csv extends FileType {
  //
//this is the appearance of the columns in the file (Mac comes first, etc.)
  static const int hostIdx = 0, macIdx = 1, ipIdx = 2;

  String fileType = g.fFormats.csv.formatName;

  @override
  Map<String, List<String>> getLeaseMap(
      {String fileContents = "",
      List<String>? fileLines,
      bool removeBadLeases = true}) {
    //
    try {
      List<String> csvRow = <String>[];

      fileContents = fileContents.trim();

      Map<String, List<String>> leaseMap = <String, List<String>>{
        g.lbHost: <String>[],
        g.lbMac: <String>[],
        g.lbIp: <String>[],
      };

      if (fileContents == "") {
        printMsg("Source file is empty or corrupt.", errMsg: true);
        return leaseMap;
      }

      List<String> csvRows = LineSplitter.split(fileContents).toList();
      if (csvRows.isEmpty) {
        throw Exception("Source file is empty: ${g.inputFile}");
      }
      List<String> keyName = csvRows[0].split(",");

      if (keyName.length < 3 ||
          !(keyName[hostIdx].contains(leaseMap.keys.elementAt(hostIdx)) &&
              keyName[macIdx].contains(leaseMap.keys.elementAt(macIdx)) &&
              keyName[ipIdx].contains(leaseMap.keys.elementAt(ipIdx)))) {
        printMsg(
            "CSV File is wrong format - must have 3 columns containing "
            "(g.lbHost, g.lbMac, g.lbIp). ",
            errMsg: true);
        throw Exception("CSV Wrong Format");
      }

      for (int i = 1; i < csvRows.length; i++) {
        csvRow = csvRows[i].split(",");

        leaseMap[keyName[hostIdx].trim()]!.add(csvRow[hostIdx].trim());
        leaseMap[keyName[macIdx].trim()]!.add(csvRow[macIdx].trim());
        leaseMap[keyName[ipIdx].trim()]!.add(csvRow[ipIdx].trim());
      }

      if (removeBadLeases) {
        return g.validateLeases
            .removeBadLeases(leaseMap, g.fFormats.csv.formatName);
      } else {
        return leaseMap;
      }
    } on Exception catch (e) {
      if ((e.toString().contains("is empty") ||
          e.toString().contains("CSV Wrong Format"))) {
        print(e);
        return <String, List<String>>{};
      } else {
        rethrow;
      }
    }
  }

  @override
  String buildOutFileContents(Map<String, List<String>?> leaseMap) {
    StringBuffer sb = StringBuffer();

    if (leaseMap[g.lbMac]!.isEmpty) {
      return "";
    }

    sb.write("host-name, mac-address, address\n");
    for (int i = 0; i < leaseMap[g.lbMac]!.length; i++) {
      sb.write(
          // ignore: lines_longer_than_80_chars
          "${leaseMap[g.lbHost]![i]},${this.reformatMacForType(leaseMap[g.lbMac]![i], fileType)},${leaseMap[g.lbIp]![i]}\n");
    }
    return sb.toString();
  }

  @override
  bool isContentValid({String fileContents = "", List<String>? fileLines}) {
    try {
      Map<String, List<String>> leaseMap =
          getLeaseMap(fileContents: fileContents, removeBadLeases: false);
      if (g.validateLeases
          .containsBadLeases(leaseMap, g.fFormats.csv.formatName)) {
        return false;
      }

      g.validateLeases.isLeaseMapListValid(leaseMap, g.fFormats.csv.formatName);

      return true;
    } on Exception catch (e) {
      printMsg(e, errMsg: true);

      return false;
    }
  }

  void csvAddColumnNamesAndRows(List<dynamic> deviceList, StringBuffer sbCsv) {
    //Add Column Names in first row
    String tmp = "";
    deviceList[0].keys.forEach((dynamic k) => tmp = "$tmp$k,");
    //Add carriage return
    tmp = tmp.replaceAll(RegExp(r',$'), "\n");
    sbCsv.write(tmp);

    //Add Rows
    for (int x = 0; x < deviceList.length; x++) {
      tmp = "";
      for (dynamic value in deviceList[x].values) {
        tmp = "$tmp$value,";
      }
      tmp = tmp.replaceAll(RegExp(r',$'), "\n");
      sbCsv.write(tmp);
    }
  }
}
