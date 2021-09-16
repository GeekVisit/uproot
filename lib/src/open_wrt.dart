import 'dart:io';

import 'globals.dart' as g;
import 'src.dart';

class OpenWrt extends FileType {
  String fileType = g.fFormats.openwrt.formatName;

  @override
  bool isFileValid(String filePath) {
    try {
      List<String> fileLines = File(filePath).readAsLinesSync();
      if (isContentValid(fileLines: fileLines)) {
        printMsg("""$filePath is valid format for $fileType""",
            onlyIfVerbose: true);
        return true;
      } else {
        printMsg("""$filePath is invalid format for $fileType)""",
            errMsg: true);
        return false;
      }
    } on Exception catch (e) {
      printMsg(e, errMsg: true);
      return false;
    }
  }

  @override
  bool isContentValid({String fileContents = "", List<String>? fileLines}) {
    try {
      ValidateLeases.clearProcessedLeases();
      if (fileContents == "" && fileLines == null) {
        throw Exception("Missing Argument for isContentValid");
      }
      dynamic leaseMap =
          getLeaseMap(fileLines: fileLines, removeBadLeases: false);

      if (g.validateLeases
          .containsBadLeases(leaseMap, g.fFormats.openwrt.formatName)) {
        return false;
      }

      g.validateLeases
          .validateLeaseList(leaseMap, g.fFormats.openwrt.formatName);
      return true;
    } on Exception catch (e) {
      printMsg(e, errMsg: true);
      return false;
    }
  }

  @override
  Map<String, List<String>> getLeaseMap(
      {String fileContents = "",
      List<String>? fileLines,
      bool removeBadLeases = true}) {
    try {
      if (fileLines == null) {
        throw Exception("Missing Argument for getLease");
      }
      Map<String, List<String>> leaseMap = <String, List<String>>{};

      //Match string between single quotes
      RegExp exp = RegExp(r"""\s['|"](.*)['|"]""", caseSensitive: false);
      //

      Map<String, String> searchParams = <String, String>{
        g.lbMac: "option mac",
        g.lbHost: "option name",
        g.lbIp: "option ip",
      };
      List<dynamic> tmp = <dynamic>[];
      List<String> tmp2 = <String>[];

      // 1) if line contains "option-mac", etc. then add to list
      //2)  search that line to match single quotes which has value,
      //3) add value to tmp list
      //4) equate the leaseMap[paramName] = temporary list
      searchParams.forEach((dynamic paramName, dynamic filter) {
        tmp = fileLines
            .where((dynamic element) => element.contains(filter))
            .toList()
            .map((dynamic e) => exp.firstMatch(e))
            .toList();

        for (dynamic element in tmp) {
          tmp2.add(element[1]); //add the value, not the parameter
        }

        leaseMap[paramName] = <String>[...tmp2];
        tmp2.clear();
        tmp.clear();
      });

      if (removeBadLeases) {
        return g.validateLeases
            .removeBadLeases(leaseMap, g.fFormats.openwrt.formatName);
      } else {
        return leaseMap;
      }
    } on Exception catch (e) {
      printMsg(e, errMsg: true);
      rethrow;
    }
  }

  @override
  String build(Map<String, List<String>?> deviceList) {
    StringBuffer sbOpenwrt = StringBuffer();
    for (int x = 0; x < deviceList[g.lbMac]!.length; x++) {
      sbOpenwrt.write("""config host
             option mac \'${deviceList[g.lbMac]?[x]}\'
             option name \'${deviceList[g.lbHost]?[x]}\'
             option ip \'${deviceList[g.lbIp]?[x]}\'
   """);
    }
    return sbOpenwrt.toString();
  }

  // ignore: slash_for_doc_comments
  /** Converts openwrt to json - 
   * NOTE: This requires override as getLeaseMap args are different 
   * from abstract class! */
  @override
  String toTmpJson() {
    Json json = Json();

    Map<String, List<String>?> lease =
        getLeaseMap(fileLines: File(g.inputFile).readAsLinesSync());

    return json.build(lease);
  }
}
