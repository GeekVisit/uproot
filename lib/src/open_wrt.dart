// Copyright 2025 GeekVisit All rights reserved.
// Use of this source code is governed by the license in the LICENSE file.

// This file defines the OpenWrt class which extends the FileType class.
// It provides methods to validate, parse, and build OpenWrt configuration files.

import 'dart:io';

import '../lib.dart';
import 'globals.dart' as g;

class OpenWrt extends FileType {
  String fileType = g.fFormats.openwrt.formatName;

  /// Validates if the file at [filePath] is a valid OpenWrt configuration file.
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
    } catch (e) {
      printMsg(e, errMsg: true);
      return false;
    }
  }

  /// Validates the content of the OpenWrt configuration file.
  /// Accepts either [fileContents] as a string or [fileLines] as a list of strings.
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
    } catch (e) {
      printMsg(e, errMsg: true);
      return false;
    }
  }

  /// Parses the OpenWrt configuration file and returns a map of leases.
  /// The map contains lists of MAC addresses, hostnames, and IP addresses.

  @override
  Map<String, List<String>> getLeaseMap(
      {String fileContents = "",
      List<String>? fileLines,
      bool removeBadLeases = true}) {
    try {
      if (fileLines == null) {
        fileLines = [];
      }
      Map<String, List<String>> leaseMap = <String, List<String>>{
        g.lbMac: <String>[],
        g.lbHost: <String>[],
        g.lbIp: <String>[],
      };

      RegExp configHostRegExp = RegExp(r'config host');
      RegExp optionMacRegExp = RegExp(r"option mac '([^']+)'");
      RegExp optionNameRegExp = RegExp(r"option name '([^']+)'");
      RegExp optionIpRegExp = RegExp(r"option ip '([^']+)'");

      int idxCurrentConfigSection = 0;

      for (String line in fileLines) {
        if (configHostRegExp.hasMatch(line)) {
//if prior entry has no name set to mac address or if not mac address, nothing
          if (idxCurrentConfigSection > 0 &&
              leaseMap[g.lbHost]!.length < leaseMap[g.lbMac]!.length) {
            fillHostNameWIthMac(leaseMap);
          }

          idxCurrentConfigSection++;
          //check for entries that have no host name, if not, then set to mac
          //this avoids errors if config has no name but will still err if mac is empty

        } else if (optionMacRegExp.hasMatch(line)) {
          leaseMap[g.lbMac]!.add(optionMacRegExp.firstMatch(line)!.group(1)!);
        } else if (optionNameRegExp.hasMatch(line)) {
          leaseMap[g.lbHost]!.add(optionNameRegExp.firstMatch(line)!.group(1)!);
        } else if (optionIpRegExp.hasMatch(line)) {
          leaseMap[g.lbIp]!.add(optionIpRegExp.firstMatch(line)!.group(1)!);
        }
      }

      //when done with all config sections check last entry for name existence

//if last entry has no name value, set name to mac address or if not mac address, nothing
      if (leaseMap[g.lbHost]!.length < leaseMap[g.lbMac]!.length) {
        fillHostNameWIthMac(leaseMap);
      }

      if (removeBadLeases) {
        return g.validateLeases
            .removeBadLeases(leaseMap, g.fFormats.openwrt.formatName);
      }
      return leaseMap;
    } on Exception catch (e) {
      printMsg(e, errMsg: true);
      rethrow;
    }
  }

  void fillHostNameWIthMac(Map<String, List<String>> leaseMap) {
    leaseMap[g.lbHost]!.add((leaseMap[g.lbMac]!.last.isNotEmpty)
        ? leaseMap[g.lbMac]!.last.toString().replaceAll(':', '-')
        : "");
  }

  /// Builds the OpenWrt configuration file content from the given [leaseMap].
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

  /// Used for Pfs and Opn conversions. Keeps and updates existing
  /// lease in merge file and adds new ones from input.
  String mergeOpenWrtConfig(Map<String, List<String>?> leaseMap) {
    try {
      StringBuffer sb = StringBuffer();

      String mergeFileContents = File(g.argResults['merge']).readAsStringSync();

      RegExp regExp = RegExp(r'((config host.*?)((config (?!host))|$))',
          multiLine: false, dotAll: true);

      String template = "";
      // update existing leases with components from the input file
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

  /// Returns OpenWrt Template To Be Used in Building File
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

      // if host ip or mac tag has a value that matches one that's in
      // leaseMap then return that static map as a template
      late Iterable<RegExpMatch> leaseMatch;
      RegExp leaseConfigRegEx = RegExp(
          r'(option.*?(name|ip|mac).*?('
          "$value"
          r').*?$)',
          caseSensitive: false,
          dotAll: true);

      String mergeFileContents =
          File(getGoodPath(g.argResults['merge'])).readAsStringSync();

      // get all config sections in the merge file
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

        // config.addAll(tmpList);
        // update ip
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
      rethrow;
    }
  }

  /// Fill in config Template with values from leaseMap
  String fillInTemplate(
      String template, Map<String, List<String>?> leaseMap, int i) {
    return template
        .replaceFirst(
            RegExp(r'^.*option mac.*?$', multiLine: true, dotAll: false),
            """  option mac '${leaseMap[g.lbMac]![i]}'""")
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
