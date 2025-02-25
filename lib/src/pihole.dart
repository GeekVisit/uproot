// Copyright 2025 GeekVisit All rights reserved.
// Use of this source code is governed by the license in the LICENSE file.

// This file defines the Pi-hole class which extends the FileType class.
// It provides methods to validate, parse, and build Pi-hole configuration files.
///
/// The `PiHole` class includes the following methods:
///
/// - `isFileValid(String filePath)`: Validates if the file at [filePath] is a valid Pi-hole configuration file.
/// - `isContentValid({String fileContents = "", List<String>? fileLines})`: Validates the content of the Pi-hole configuration file. Accepts either [fileContents] as a string or [fileLines] as a list of strings.
/// - `getLeaseMap({String fileContents = "", List<String>? fileLines, bool removeBadLeases = true})`: Parses the Pi-hole configuration file and returns a map of leases. The map contains lists of MAC addresses, hostnames, and IP addresses.
/// - `fillHostNameWIthMac(Map<String, List<String>> leaseMap)`: Fills the host name with the MAC address if the host name is not provided.
/// - `buildOutFileContents(Map<String, List<String>?> leaseMap)`: Builds the Pi-hole configuration file content from the given [leaseMap].
/// - `mergePiHoleConfig(Map<String, List<String>?> leaseMap)`: Used for Pfs and Opn conversions. Keeps and updates existing leases in the merge file and adds new ones from input.
/// - `getPiHoleTemplate(Map<String, List<String>?> leaseMap, int i)`: Returns Pi-hole template to be used in building the file.
/// - `fillInTemplate(String template, Map<String, List<String>?> leaseMap, int i)`: Fills in the config template with values from the lease map.

import 'dart:io';

import '../lib.dart';
import 'globals.dart' as g;

class PiHole extends FileType {
  String fileType = g.fFormats.pihole.formatName;

  /// Validates if the file at [filePath] is a valid Pi-hole configuration file.
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

  /// Validates the content of the Pi-hole configuration file.
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
        throw Exception("Missing Argument for isContentValid Pi-hole");
      }
      dynamic leaseMap =
          getLeaseMap(fileLines: fileLines, removeBadLeases: false);

      if (g.validateLeases
          .containsBadLeases(leaseMap, g.fFormats.pihole.formatName)) {
        return false;
      }

      g.validateLeases
          .isLeaseMapListValid(leaseMap, g.fFormats.pihole.formatName);
      return true;
    } catch (e) {
      printMsg(e, errMsg: true);
      return false;
    }
  }

  /// Parses the Pi-hole configuration file and returns a map of leases.
  /// The map contains lists of MAC addresses, hostnames, and IP addresses.

  @override
  Map<String, List<String>> getLeaseMap(
      {String fileContents = "",
      List<String>? fileLines,
      bool removeBadLeases = true}) {
    try {
      if (fileLines == null && fileContents != "") {
        fileLines = fileContents.split("\n");
      }
      Map<String, List<String>> leaseMap = <String, List<String>>{
        g.lbMac: <String>[],
        g.lbHost: <String>[],
        g.lbIp: <String>[],
      };

      RegExp dhcpHostRegExp =
          RegExp(r"dhcp-host=([^,]+),([^,]+),(([^,]+))?,?$");

      for (String line in fileLines!) {
        if (dhcpHostRegExp.hasMatch(line)) {
          RegExpMatch match = dhcpHostRegExp.firstMatch(line)!;
          //replace dashes with colons
          leaseMap[g.lbMac]!.add(match.group(1)!);
          leaseMap[g.lbIp]!.add(match.group(2)!);
          //if there is no match for a host set same as mac but replace colons with hyphens
          leaseMap[g.lbHost]!.add((match.group(3) == null)
              ? leaseMap[g.lbMac]!.last.replaceAll(':', '-').toString()
              : match.group(3).toString());
        }
      }

      if (removeBadLeases) {
        return g.validateLeases
            .removeBadLeases(leaseMap, g.fFormats.pihole.formatName);
      }
      return leaseMap;
    } on Exception catch (e) {
      printMsg(e, errMsg: true);
      rethrow;
    }
  }

  /// Builds the Pi-hole configuration file content from the given [leaseMap].
  @override
  String buildOutFileContents(Map<String, List<String>?> leaseMap) {
    StringBuffer sbPiHole = StringBuffer();

    dynamic mergeTargetFileType = (g.argResults['merge'] != null)
        ? g.cliArgs.getInputTypeAbbrev(getGoodPath(g.argResults['merge']))
        : "";

    if (g.argResults['merge'] != null && mergeTargetFileType == "o") {
      return mergePiHoleConfig(leaseMap);
    }

    for (int x = 0; x < leaseMap[g.lbMac]!.length; x++) {
      sbPiHole.write(
          """dhcp-host=${this.reformatMacForType(leaseMap[g.lbMac]![x], fileType)},${leaseMap[g.lbIp]?[x].trim()},${leaseMap[g.lbHost]?[x].trim()}
""");
    }

    return sbPiHole.toString();
  }

  /// Keeps and updates existing
  /// lease in merge file and adds new ones from input.
  String mergePiHoleConfig(Map<String, List<String>?> leaseMap) {
    try {
      StringBuffer sb = StringBuffer();

      String mergeFileContents = File(g.argResults['merge']).readAsStringSync();

      RegExp regExp = RegExp(r'((config host.*?)((config (?!host))|$))',
          multiLine: false, dotAll: true);

      String template = "";
      // update existing leases with components from the input file
      for (int i = 0; i < leaseMap[g.lbMac]!.length; i++) {
        template = getPiHoleTemplate(
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

  /// Returns Pi-hole Template To Be Used in Building File
  String getPiHoleTemplate(Map<String, List<String>?> leaseMap, int i) {
    try {
      String genericConfigTemplate = """
dhcp-host=mac-A1B2C3,ip-A1B2C3,name-A1B2C3
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
        .replaceFirst("mac-A1B2C3", leaseMap[g.lbMac]![i])
        .trim()
        .replaceFirst("ip-A1B2C3", leaseMap[g.lbIp]![i])
        .trim()
        .replaceFirst("host-A1B2C3", leaseMap[g.lbHost]![i])
        .trim();
  }
}
