import 'dart:io';
import 'src.dart';

class OpenWrt extends FileType {
  String fileType = fFormats.openwrt.formatName;

  @override
  bool isFileValid(String filePath) {
    try {
      List<String> fileLines = File(filePath).readAsLinesSync();
      if (isContentValid(fileLines: fileLines)) {
        printMsg("""$filePath is valid format for $fileType""",
            onlyIfVerbose: true);
        return true;
      } else {
        printMsg("""$filePath is invalid format for $fileType)}""",
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
      ValidateLeases.initialize();
      if (fileContents == "" && fileLines == null) {
        throw Exception("Missing Argument for isContentValid");
      }
      dynamic leaseMap = getLease(fileLines: fileLines, removeBadLeases: false);

      if (validateLeases.containsBadLeases(leaseMap)) {
        return false;
      }

      validateLeases.validateLeaseList(leaseMap, fFormats.openwrt.formatName);
      return true;
    } on Exception catch (e) {
      printMsg(e, errMsg: true);
      return false;
    }
  }

  @override
  Map<String, List<String>> getLease(
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
        lbMac: "option mac",
        lbHost: "option name",
        lbIp: "option ip",
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
        return validateLeases.getValidLeaseMap(
            leaseMap, fFormats.openwrt.formatName);
      } else {
        return leaseMap;
      }
    } on Exception catch (e) {
      printMsg(e, errMsg: true);
      rethrow;
    }
  }

  @override
  String build(Map<String, List<String>?> deviceList, StringBuffer sbOpenwrt) {
    for (int x = 0; x < deviceList[lbHost]!.length; x++) {
      sbOpenwrt.write("""config host
             option mac \'${deviceList[lbMac]?[x]}\'
             option name \'${deviceList[lbHost]?[x]}\'
             option ip \'${deviceList[lbIp]?[x]}\'
   """);
    }
    return sbOpenwrt.toString();

    //verify whether file is a valid openwrt configuration file
  }

  @override
  String toJson() {
    StringBuffer sbJson = StringBuffer();
    Json json = Json();

    Map<String, List<String>?> lease =
        getLease(fileLines: File(argResults['input-file']).readAsLinesSync());

    json.build(lease, sbJson);

    return "[ ${sbJson.toString()} ]";
  }
}
