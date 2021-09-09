import 'dart:io';
import 'globals.dart' as g;
import 'src.dart';

class Ddwrt extends FileType {
  //
  //this is the appearance of the properties in the file (Mac comes first, etc.)
  static const int macIdx = 0, hostIdx = 1, ipIdx = 2;

  String fileType = g.fFormats.ddwrt.formatName;

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
        g.lbMac: <String>[],
        g.lbHost: <String>[],
        g.lbIp: <String>[],
      };

      List<String> lease = fileContents.split(' ');

      for (int x = 0; x < lease.length; x++) {
        List<String> leaseProperty = lease[x].split('=');

        if (leaseProperty.length < 3) {
          throw Exception("Corrupt DDwrt File, lease component mismatch. ");
        }

        leaseMap[g.lbMac]!.add(leaseProperty[macIdx]);
        leaseMap[g.lbHost]!.add(leaseProperty[hostIdx]);
        leaseMap[g.lbIp]!.add(leaseProperty[ipIdx]);
      }

      if (removeBadLeases) {
        return g.validateLeases
            .getValidLeaseMap(leaseMap, g.fFormats.ddwrt.formatName);
      } else {
        return leaseMap;
      }
    } on Exception catch (e) {
      printMsg(e, errMsg: true);

      rethrow;
    }
  }

  String build(Map<String, List<String>?> deviceList, StringBuffer sbDdwrt) {
    for (int x = 0; x < deviceList[g.lbHost]!.length; x++) {
      sbDdwrt.write(
          """${deviceList[g.lbMac]?[x]}=${deviceList[g.lbHost]?[x]}=${deviceList[g.lbIp]?[x]}=1440 """);
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

      if (g.validateLeases
          .containsBadLeases(leaseMap, g.fFormats.ddwrt.formatName)) {
        return false;
      }
      g.validateLeases.validateLeaseList(leaseMap, g.fFormats.ddwrt.formatName);

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
    String inFileContents = File(g.inputFile).readAsStringSync();

    //get leases from ddwrt file
    Map<String, List<String>> lease = getLease(fileContents: inFileContents);

    //convert leases to json format
    for (int x = 0; x < lease[g.lbHost]!.length; x++) {
      if (sbJson.isNotEmpty) sbJson.write(',');

      sbJson.write('{ g.lbMac : "${lease[g.lbMac]![x]}",'
          ' g.lbHost : "${lease[g.lbHost]![x]}", g.lbIp : '
          '"${lease[g.lbIp]![x]}" }');
    }
    return "[ ${sbJson.toString()} ]";
  }
}
