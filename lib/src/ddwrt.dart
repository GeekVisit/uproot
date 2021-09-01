import 'dart:io';
import '../lib.dart';

class Ddwrt extends FileType {
  //
  //this is the appearance of the properties in the file (Mac comes first, etc.)
  static const int macIdx = 0, hostIdx = 1, ipIdx = 2;

  String fileType = fFormats.ddwrt.formatName;

  @override
  //Given a string this returns Maps of the a list of each lease
  Map<String, List<String>> getLease(
      {String fileContents = "",
      List<String>? fileLines,
      bool removeBadLeases = true}) {
    //

    try {
      if (fileContents == "") {
        throw Exception("Missing Argument for getLease");
      }

      Map<String, List<String>> leaseMap = <String, List<String>>{
        lbMac: <String>[],
        lbHost: <String>[],
        lbIp: <String>[],
      };

      List<String> lease = fileContents.split(' ');

      for (int x = 0; x < lease.length; x++) {
        List<String> leaseProperty = lease[x].split('=');

        if (leaseProperty.length < 3) {
          throw Exception("Corrupt DDwrt File, lease component mismatch. ");
        }

        leaseMap[lbMac]!.add(leaseProperty[macIdx]);
        leaseMap[lbHost]!.add(leaseProperty[hostIdx]);
        leaseMap[lbIp]!.add(leaseProperty[ipIdx]);
      }

      if (removeBadLeases) {
        return validateLeases.getValidLeaseMap(
            leaseMap, fFormats.ddwrt.formatName);
      } else {
        return leaseMap;
      }
    } on Exception catch (e) {
      printMsg(e, errMsg: true);

      rethrow;
    }
  }

  String build(Map<String, List<String>?> deviceList, StringBuffer sbDdwrt) {
    for (int x = 0; x < deviceList[lbHost]!.length; x++) {
      sbDdwrt.write(
          """${deviceList[lbMac]?[x]}=${deviceList[lbHost]?[x]}=${deviceList[lbIp]?[x]}=1440 """);
    }
    return sbDdwrt.toString();
  }

  @override
  bool isContentValid({String fileContents = "", List<String>? fileLines}) {
    try {
      ValidateLeases.initialize();
      if (fileContents == "") {
        throw Exception("Missing Argument for getLease");
      }

      dynamic leaseMap =
          getLease(fileContents: fileContents, removeBadLeases: false);

      if (validateLeases.containsBadLeases(leaseMap)) {
        return false;
      }
      validateLeases.validateLeaseList(leaseMap, fFormats.ddwrt.formatName);

      return true;
    } on Exception catch (e) {
      printMsg(e, errMsg: true);
      return false;
    }
  }

  @override
  //Converts DDwrt to Json, returns json string
  String toJson() {
    StringBuffer sbJson = StringBuffer();
    String inFileContents = File(argResults['input-file']).readAsStringSync();

    //get leases from ddwrt file
    Map<String, List<String>> lease = getLease(fileContents: inFileContents);

    //convert leases to json format
    for (int x = 0; x < lease[lbHost]!.length; x++) {
      if (sbJson.isNotEmpty) sbJson.write(',');

      sbJson.write('{ $lbMac : "${lease[lbMac]![x]}",'
          ' $lbHost : "${lease[lbHost]![x]}", $lbIp : '
          '"${lease[lbIp]![x]}" }');
    }
    return "[ ${sbJson.toString()} ]";
  }
}
