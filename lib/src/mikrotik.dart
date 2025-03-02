// Copyright 2025 GeekVisit All rights reserved.
// Use of this source code is governed by the license in the LICENSE file.

import '../lib.dart';
import 'globals.dart' as g;


/// A class representing Mikrotik file type operations.
///
/// This class extends the `FileType` class and provides methods to handle
/// Mikrotik file contents and extract lease information.
///
/// Properties:
/// - `fileType`: A string representing the format name of the Mikrotik file.
///
/// Methods:
/// - `getLeaseMap`: Extracts lease information from the given Mikrotik file contents.
///
///   Parameters:
///   - `fileContents` (String): The contents of the Mikrotik file. Default is an empty string.
///   - `fileLines` (List<String>?): A list of lines from the file. Default is null.
///   - `removeBadLeases` (bool): A flag indicating whether to remove bad leases. Default is true.
///
///   Returns:
///   - `Map<String, List<String>>`: A map containing lease information categorized by host, MAC, and IP.
///
///   Throws:
///   - `Exception`: If an error occurs during the processing of the file contents.
class Mikrotik extends FileType {
  //

  String fileType = g.fFormats.mikrotik.formatName;

  Map<String, List<String>> getLeaseMap(
      {String fileContents = "",
      List<String>? fileLines,
      bool removeBadLeases = true}) {
    try {
      Map<String, List<String>> leaseMap = <String, List<String>>{
        g.lbHost: <String>[],
        g.lbMac: <String>[],
        g.lbIp: <String>[]
      };

      bool isOutPutFile = fileContents.contains("/ip dns static");

      if (fileContents == "") {
        printMsg("Source file is empty or corrupt.", errMsg: true);
        return leaseMap;
      }

      fileLines = fileContents.split("\n");

      if (isOutPutFile) {
        fillLeaseMapWithMikrotikOutputFile(fileLines, fileContents, leaseMap);
      } else {
        fillLeaseMapFromMikrotikInputFile(fileLines, fileContents, leaseMap);
      }

      if (removeBadLeases) {
        return g.validateLeases
            .removeBadLeases(leaseMap, g.fFormats.mikrotik.formatName);
      } else {
        return leaseMap;
      }
    } on Exception catch (e) {
      printMsg(e, errMsg: true);
      rethrow;
    }
  }

  void fillLeaseMapWithMikrotikOutputFile(List<String> fileLines,
      String fileContents, Map<String, List<String>> leaseMap) {
    final sectionRegEx = RegExp("/ip dhcp-server lease");

    final ipRegEx =
        RegExp(r'\smac-address=.*?address\s*=\s*((?:\d{1,3}\.){3}\d{1,3})');

    final macRegEx =
        RegExp(r'mac-address=(([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2}))');

    final hostRegEx = RegExp(r'\sname=([\w\-\.]+)');

    int idxCurrentSection = 0;
    for (var line in fileLines) {
      if (sectionRegEx.hasMatch(line)) {
        if (idxCurrentSection > 0 &&
            leaseMap[g.lbHost]!.length < leaseMap[g.lbMac]!.length) {
          fillHostNameWithMac(leaseMap);
        }

        idxCurrentSection++;
      } else if (macRegEx.hasMatch(line)) {
        leaseMap[g.lbMac]!.add(macRegEx.firstMatch(line)!.group(1)!);

        if (ipRegEx.hasMatch(line)) {
          leaseMap[g.lbIp]!.add(ipRegEx.firstMatch(line)!.group(1)!);
        }
      } else if (hostRegEx.hasMatch(line)) {
        leaseMap[g.lbHost]!.add(hostRegEx.firstMatch(line)!.group(1)!);
      }
    }
    //after file has been processed check for hostName again
    if (leaseMap[g.lbHost]!.length < leaseMap[g.lbMac]!.length) {
      fillHostNameWithMac(leaseMap);
    }
  }

  void fillLeaseMapFromMikrotikInputFile(List<String> fileLines,
      String fileContents, Map<String, List<String>> leaseMap) {
    for (var line in fileLines) {
      var ipMatch =
          RegExp(r'\saddress\s*=\s*((?:\d{1,3}\.){3}\d{1,3})').firstMatch(line);

      final macMatch =
          RegExp(r'mac-address=(([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2}))')
              .firstMatch(line);
      var hostMatch = RegExp(r'host-name=([\w\-\.]+)').firstMatch(line);

      //skip lines that don't have ip or mac addresses
      if (ipMatch == null || macMatch == null) {
        continue;
      }

      final ip = ipMatch.group(1) ?? '';
      final mac = macMatch.group(1) ?? '';
      final host = hostMatch?.group(1) ?? mac.replaceAll(':', '-');

      leaseMap[g.lbIp]!.add(ip);
      leaseMap[g.lbMac]!.add(mac);
      leaseMap[g.lbHost]!.add(host);
    }
  }

  @override
  String buildOutFileContents(Map<String, List<String>?> leaseMap) {
    StringBuffer sbMikrotik = StringBuffer();
    for (int x = 0; x < leaseMap[g.lbMac]!.length; x++) {
      //if hostname is empty then fill it in with mac address with dashes
      if (leaseMap[g.lbHost]![x] == "") {
        leaseMap[g.lbHost]![x] = leaseMap[g.lbMac]![x].replaceAll(":", "-");
      }
      //two lines in rsc script - one to add mac/ip static lease, one to add hostname
      sbMikrotik.write("""\n/ip dhcp-server lease""");
      sbMikrotik.write(
          """\nadd mac-address=${this.reformatMacForType(leaseMap[g.lbMac]![x], fileType)} address=${leaseMap[g.lbIp]?[x]} server=${g.argResults['server']}""");
      sbMikrotik.write("""\n/ip dns static""");
      sbMikrotik.write(
          """\nadd address=${leaseMap[g.lbIp]?[x]} name=${leaseMap[g.lbHost]?[x]}""");
    }
    var result = "${sbMikrotik.toString().trim()}";
    return result;
  }

  void fillHostNameWithMac(Map<String, List<String>> leaseMap) {
    leaseMap[g.lbHost]!.add((leaseMap[g.lbMac]!.last.isNotEmpty)
        ? leaseMap[g.lbMac]!.last.toString().replaceAll(':', '-')
        : "");
  }

  @override
  bool isContentValid({String fileContents = "", List<String>? fileLines}) {
    try {
      ValidateLeases.clearProcessedLeases();
      if (fileContents == "") {
        throw Exception("File Contents is Empty");
      }

      if (!fileContents.contains("/ip dhcp-server lease")) return false;

      Map<String, List<String>> leaseMap =
          getLeaseMap(fileContents: fileContents, removeBadLeases: false);

      if (g.validateLeases
          .containsBadLeases(leaseMap, g.fFormats.mikrotik.formatName)) {
        return false;
      }

      g.validateLeases
          .isLeaseMapListValid(leaseMap, g.fFormats.mikrotik.formatName);

      return true;
    } on Exception catch (e) {
      printMsg(e, errMsg: true);
      return false;
    }

    //
  }
}