import 'globals.dart' as g;
import 'src.dart';

class Ddwrt extends FileType {
  //
  //this is the appearance of the properties in the file (Mac comes first, etc.)
  static const int macIdx = 0, hostIdx = 1, ipIdx = 2;

  String fileType = g.fFormats.ddwrt.formatName;

  @override
  //Given a string this returns Maps of the a list of each lease
  Map<String, List<String>> getLeaseMap(
      {String fileContents = "",
      List<String>? fileLines,
      bool removeBadLeases = true}) {
    //

    try {
      if (fileContents == "") {
        throw Exception("Missing Argument for getLeaseMap in Ddwrt");
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
          printMsg("Bad Lease: ${leaseProperty.join(" ")} Skipping ...");
          continue;
        }

        leaseMap[g.lbMac]!.add(leaseProperty[macIdx]);
        leaseMap[g.lbHost]!.add(leaseProperty[hostIdx]);
        leaseMap[g.lbIp]!.add(leaseProperty[ipIdx]);
      }

      if (removeBadLeases) {
        return g.validateLeases
            .removeBadLeases(leaseMap, g.fFormats.ddwrt.formatName);
      } else {
        return leaseMap;
      }
    } on Exception catch (e) {
      printMsg(e, errMsg: true);

      rethrow;
    }
  }

  String build(Map<String, List<String>?> deviceList) {
    StringBuffer sbDdwrt = StringBuffer();
    for (int x = 0; x < deviceList[g.lbMac]!.length; x++) {
      sbDdwrt.write(
          """${deviceList[g.lbMac]?[x]}=${deviceList[g.lbHost]?[x]}=${deviceList[g.lbIp]?[x]}=1440 """);
    }
    return sbDdwrt.toString();
  }

  @override
  bool isContentValid({String fileContents = "", List<String>? fileLines}) {
    try {
      ValidateLeases.clearProcessedLeases();
      if (fileContents == "") {
        throw Exception("Missing Argument for isContentsValid Ddwrt");
      }

      dynamic leaseMap =
          getLeaseMap(fileContents: fileContents, removeBadLeases: false);

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
}
