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
      if (fileContents != "" && fileLines == null) {
        fileLines = fileContents
            .split("\n")
            // ignore: always_specify_types
            .map((e) => e.trim())
            .where((dynamic e) => e.length != 0)
            .toList();
      }

      if (fileLines == null) {
        throw Exception("Missing Argument for isContentValid OpenWrt");
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
      if (fileLines == null && fileContents != "") {
        fileLines = fileContents
            .split("\n")
            // ignore: always_specify_types
            .map((e) => e.trim())
            .where((dynamic e) => e.length != 0)
            .toList();
      }

      if (fileLines == null) {
        throw Exception("Missing Argument for getLeaseMap in OpenWrt");
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
        tmp = fileLines!
            .where((dynamic element) => element.contains(filter))
            .toList()
            .map((dynamic e) => exp.firstMatch(e))
            .toList();

        for (dynamic element in tmp) {
          tmp2.add(element[1]); //add the value, not the parameter
        }
        //copy into leaseMap
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
  String build(Map<String, List<String>?> leaseMap) {
    StringBuffer sbOpenwrt = StringBuffer();

    dynamic mergeTargetFileType = (g.argResults['merge'] != null)
        ? g.cliArgs.getFormatTypeOfFile(getGoodPath(g.argResults['merge']))
        : "";

    if (g.argResults['merge'] != null && mergeTargetFileType == "o") {
      return mergeOpenWrtConfig(leaseMap);
    }

    for (int x = 0; x < leaseMap[g.lbMac]!.length; x++) {
      sbOpenwrt.write("""config host
             option mac \'${leaseMap[g.lbMac]?[x]}\'
             option name \'${leaseMap[g.lbHost]?[x]}\'
             option ip \'${leaseMap[g.lbIp]?[x]}\'
   """);
    }

    return sbOpenwrt.toString();
  }

  // ignore: slash_for_doc_comments
  /**  Used for Pfs and Opn conversions. Keeps and updates existing
   *  lease in merge file and adds new ones from input. 
  */
  String mergeOpenWrtConfig(Map<String, List<String>?> leaseMap) {
    try {
      StringBuffer sb = StringBuffer();

      String mergeFileContents = File(g.argResults['merge']).readAsStringSync();

      RegExp regExp = RegExp(r'((config host.*?)((config (?!host))|$))',
          multiLine: false, dotAll: true);

      //TODO: Concept: find configs by regex, then search and
      //replace old config with new
      //config

      String template = "";
      //update existing leases with components from the input file
      for (int i = 0; i < leaseMap[g.lbMac]!.length; i++) {
        template = getOpenWrtTemplate(
          leaseMap,
          i,
        );

        sb.write("\n${fillInTemplate(template, leaseMap, i)}");
      }

      return mergeFileContents.replaceAll(regExp, "") + sb.toString();
    } on Exception {
      rethrow;
    }
  }

  /// Returns OpenWrt Template To Be Used in Building File */
  String getOpenWrtTemplate(Map<String, List<String>?> leaseMap, int i) {
    try {
      String genericConfigTemplate = """
config host
    option mac
    option name
    option ip
""";

      String value = "${leaseMap[g.lbHost]![i]}|${leaseMap[g.lbMac]![i]}"
          "|${leaseMap[g.lbIp]![i]}";

      //if host ip or mac tag has a value that matches one that's in
      //leaseMap then return that static map as a template
      late Iterable<RegExpMatch> leaseMatch;
      RegExp leaseConfigRegEx = RegExp(
          r'(option.*?(name|ip|mac).*?('
          "$value"
          r').*?$)',
          caseSensitive: false,
          dotAll: true);

      String mergeFileContents =
          File(getGoodPath(g.argResults['merge'])).readAsStringSync();

      //get all config sections in the merge file
      RegExp regExp = RegExp(r'((config host.*?)((config (?!host))|$))',
          multiLine: false, dotAll: true);

      Iterable<RegExpMatch> staticLeaseConfigSections =
          regExp.allMatches(mergeFileContents);
      if (staticLeaseConfigSections.isEmpty) {
        "Skipping merging leases, none found in merge file";
      }

      List<String> staticLeaseConfigSection = <String>[];

      outerLoop:
      for (int i = 0; i < staticLeaseConfigSections.length; i++) {
        staticLeaseConfigSection = staticLeaseConfigSections
            .elementAt(0)
            .group(0)!
            .split("config host")
            // ignore: always_specify_types
            .map((e) => e.trim())
            .toList();

        staticLeaseConfigSection.removeAt(0);

        //config.addAll(tmpList);
        //update ip
        for (String eachConfig in staticLeaseConfigSection) {
          leaseMatch = leaseConfigRegEx.allMatches(eachConfig);
          if (leaseMatch.isNotEmpty) break outerLoop;
        }
      }

      if (leaseMatch.isNotEmpty) {
        return """config host 
                  ${leaseMatch.elementAt(0).group(0)!}""";
      } else {
        return genericConfigTemplate;
      }
    } on Exception {
      // TODO
      rethrow;
    }
  }

  String fillInTemplate(
      String template, Map<String, List<String>?> leaseMap, int i) {
    return template
        .replaceFirst(
            RegExp(r'^.*option mac.*?$', multiLine: true, dotAll: false),
            """        option mac '${leaseMap[g.lbMac]![i]}'""")
        .trim()
        .replaceFirst(
            RegExp(r'option name.*?$', multiLine: true, dotAll: false),
            "option name '${leaseMap[g.lbHost]![i]}'")
        .trim()
        .replaceFirst(RegExp(r'option ip.*?$', multiLine: true, dotAll: false),
            "option ip '${leaseMap[g.lbIp]![i]}'")
        .trim();
  }
}
