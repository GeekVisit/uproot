import 'dart:io';
import 'globals.dart' as g;
import 'src.dart';

class Mikrotik extends FileType {
  //

  String fileType = g.fFormats.mikrotik.formatName;

  Map<String, List<String>> getLeaseMap(
      {String fileContents = "",
      List<String>? fileLines,
      bool removeBadLeases = true}) {
    if (fileContents == "" && fileLines == null) {
      throw Exception("Missing Argument for getLease");
    }
    try {
      List<String> fileLines = extractLeaseMatches(fileContents);

      Map<String, List<String>> leaseMap = <String, List<String>>{
        g.lbHost: extractLeaseParam(fileLines, "name"),
        g.lbMac: extractLeaseParam(fileLines, g.lbMac),
        g.lbIp: extractLeaseParam(fileLines, g.lbIp)
      };

      if (removeBadLeases) {
        return g.validateLeases
            .getGoodLeaseMap(leaseMap, g.fFormats.mikrotik.formatName);
      } else {
        return leaseMap;
      }
    } on Exception catch (e) {
      printMsg(e, errMsg: true);
      rethrow;
    }
  }

  String build(Map<String, List<String>?> deviceList, StringBuffer sbMikrotik) {
    for (int x = 0; x < deviceList[g.lbHost]!.length; x++) {
      sbMikrotik.write(
          """\nadd mac-address=${deviceList[g.lbMac]?[x]} address=${deviceList[g.lbIp]?[x]} server=${g.argResults['server']}""");
    }
    return "/ip dhcp-server lease\n${sbMikrotik.toString().trim()}";
  }

  @override
  bool isContentValid({String fileContents = "", List<String>? fileLines}) {
    try {
      ValidateLeases.initialize();
      if (fileContents == "") {
        throw Exception("File Contents is Empty");
      }

      if (!fileContents.contains("/ip dhcp-server lease")) return false;

      /*   List<String> importList = extractLeaseMatches(fileContents);
      Map<String, List<String>> leaseMap =
          getLease(fileLines: importList, removeBadLeases: false); */

      Map<String, List<String>> leaseMap =
          getLeaseMap(fileContents: fileContents, removeBadLeases: false);

      if (g.validateLeases
          .containsBadLeases(leaseMap, g.fFormats.mikrotik.formatName)) {
        return false;
      }

      g.validateLeases
          .validateLeaseList(leaseMap, g.fFormats.mikrotik.formatName);

      return true;
    } on Exception catch (e) {
      printMsg(e, errMsg: true);
      return false;
    }
  }

//find parameters with values around =
  List<String> extractLeaseMatches(String inFileContents) {
    try {
      RegExp regExp = RegExp(r"(\S*?=\S*?\s|\S*?$)");

      //Get List of all Parameters/Values separated by equals
      List<String> importList = regExp
          .allMatches(inFileContents)
          .map((dynamic m) => m[0].trim().toString())
          .toList();
      return importList;
    } on Exception catch (e) {
      printMsg(e, errMsg: true);
      rethrow;
    }
  }

  List<String> extractLeaseParam(List<String>? importList, String paramType) {
    try {
      List<String> leaseParamList = <String>[];

      List<dynamic> param = importList!
          .where((dynamic element) => (paramType == g.lbIp
              ? element.contains(g.lbIp) && !element.contains(g.lbMac)
              : element.contains(paramType)))
          //.where((dynamic element) => (element.contains(paramType)))
          .map((dynamic e) => (e.split("=")))
          .toList();

      for (dynamic element in param) {
        leaseParamList.add(element[1].toString());
      }

      return leaseParamList;
    } on Exception catch (e) {
      printMsg(e, errMsg: true);
      rethrow;
    }
  }

  @override
  String toJson() {
    Json json = Json();
    StringBuffer sbJson = StringBuffer();

    Map<String, List<String>?> leaseMap =
        getLeaseMap(fileContents: File(g.inputFile).readAsStringSync());

    return json.build(leaseMap, sbJson);
  }

  //
}
