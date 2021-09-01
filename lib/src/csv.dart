import 'dart:convert';
import 'dart:io';

import '../lib.dart';

class Csv extends FileType {
  //
//this is the appearance of the columns in the file (Mac comes first, etc.)
  static const int hostIdx = 0, macIdx = 1, ipIdx = 2;

  String fileType = fFormats.csv.formatName;

  //Returns Lease map containing list of hostnames, macs, etc.
  //

  @override
  Map<String, List<String>> getLease(
      {String fileContents = "",
      List<String>? fileLines,
      bool removeBadLeases = true}) {
    //
    try {
      List<String> csvRow = <String>[];

      fileContents = fileContents.trim();
      if (fileContents == "" && fileLines == null) {
        throw Exception("Missing Argument for getLease");
      }

      Map<String, List<String>> leaseMap = <String, List<String>>{
        lbHost: <String>[],
        lbMac: <String>[],
        lbIp: <String>[],
      };
      List<String> csvRows = LineSplitter.split(fileContents).toList();
      List<String> keyName = csvRows[0].split(",");

      if (keyName.length != 3 ||
          !(keyName[hostIdx].contains(leaseMap.keys.elementAt(hostIdx)) &&
              keyName[macIdx].contains(leaseMap.keys.elementAt(macIdx)) &&
              keyName[ipIdx].contains(leaseMap.keys.elementAt(ipIdx)))) {
        printMsg(
            "CSV File is wrong format - must have 3 columns containing "
            "($lbHost, $lbMac, $lbIp). ",
            errMsg: true);
        throw Exception("Error: CSV Wrong Format");
      }

      for (int i = 1; i < csvRows.length; i++) {
        csvRow = csvRows[i].split(",");

        leaseMap[keyName[hostIdx].trim()]!.add(csvRow[hostIdx].trim());
        leaseMap[keyName[macIdx].trim()]!.add(csvRow[macIdx].trim());
        leaseMap[keyName[ipIdx].trim()]!.add(csvRow[ipIdx].trim());
      }

      if (removeBadLeases) {
        return validateLeases.getValidLeaseMap(
            leaseMap, fFormats.csv.formatName);
      } else {
        return leaseMap;
      }
    } on Exception {
      rethrow;
    }
  }

  @override
  String build(Map<String, List<String>?> deviceList, StringBuffer sbCsv) {
    sbCsv.write("host-name, mac-address, address\n");
    for (int i = 0; i < deviceList[lbHost]!.length; i++) {
      sbCsv.write(
          // ignore: lines_longer_than_80_chars
          "${deviceList[lbHost]![i]},${deviceList[lbMac]![i]},${deviceList[lbIp]![i]}\n");
    }
    return sbCsv.toString();
  }

  @override
  bool isContentValid({String fileContents = "", List<String>? fileLines}) {
    ValidateLeases.initialize();
    try {
      Map<String, List<String>> leaseMap =
          getLease(fileContents: fileContents, removeBadLeases: false);
      if (fileContents == "" && fileLines == null) {
        throw Exception("Missing Argument for isContentValid");
      }
      if (validateLeases.containsBadLeases(leaseMap)) {
        return false;
      }

      validateLeases.validateLeaseList(leaseMap, fFormats.csv.formatName);

      return true;
    } on Exception catch (e) {
      printMsg(e, errMsg: true);

      return false;
    }
  }

  @override
  String toJson() {
    Json json = Json();
    StringBuffer sbJson = StringBuffer();
    isFileValid(File(argResults['input-file']).absolute.path);
    Map<String, List<String>> lease = getLease(
        fileContents: File(File(argResults['input-file']).absolute.path)
            .readAsStringSync());
    return json.build(lease, sbJson);
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
