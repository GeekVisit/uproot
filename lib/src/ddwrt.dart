// Copyright 2025 GeekVisit All rights reserved.
// Use of this source code is governed by the license in the LICENSE file.

import 'dart:ffi';

import '../lib.dart';
import 'globals.dart' as g;

/// A class representing the DD-WRT file type, extending the FileType class.
/// This class provides methods to parse and validate DD-WRT lease files.
///
/// Properties:
/// - `macIdx`: Index for MAC address in the lease properties.
/// - `hostIdx`: Index for Hostname in the lease properties.
/// - `ipIdx`: Index for IP address in the lease properties.
/// - `fileType`: The format name of the DD-WRT file type.
///
/// Methods:
/// - `getLeaseMap`: Parses the given file contents and returns a map of leases.
/// - `build`: Constructs a DD-WRT formatted string from a map of device lists.
/// - `isContentValid`: Validates the content of the DD-WRT file.
class Ddwrt extends FileType {
  //
  //this is the appearance of the properties in the file (Mac comes first, etc.)
  static const int macIdx = 0, hostIdx = 1, ipIdx = 2;

  String fileType = g.fFormats.ddwrt.formatName;

  @override
  //Given a string this returns Maps of  a list of each lease
  Map<String, List<String>> getLeaseMap(
      {String fileContents = "",
      List<String>? fileLines,
      bool removeBadLeases = true}) {
    //

    try {
      Map<String, List<String>> leaseMap = <String, List<String>>{
        g.lbMac: <String>[],
        g.lbHost: <String>[],
        g.lbIp: <String>[],
      };

      if (fileContents == "") {
        printMsg("Error: Source file is empty.", errMsg: true);
        return leaseMap;
      }

      // Define the regular expression to match the MAC address, hostname, and IP address
      RegExp regExp = RegExp(r'([0-9A-Fa-f:]+)=([^=]+)=([0-9.]+)');

      // Find all matches in the fileContents
      Iterable<RegExpMatch> matches = regExp.allMatches(fileContents);

      // Extract the MAC address, hostname, and IP address and add them to the leaseMap
      for (RegExpMatch match in matches) {
        leaseMap[g.lbMac]!.add(match.group(1)!);
        leaseMap[g.lbHost]!.add(match.group(2)!);
        leaseMap[g.lbIp]!.add(match.group(3)!);
      }

      ///replace all quotes that might be in values
      leaseMap.updateAll((key, valueList) {
        return valueList.map((value) => value.replaceAll('"', '')).toList();
      });

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

  @override
  String buildOutFileContents(Map<String, List<String>?> leaseMap) {
    StringBuffer sbDdwrt = StringBuffer();

    ///replace all quotes that might be in values
    leaseMap.updateAll((key, valueList) {
      return valueList!.map((value) => value.replaceAll('"', '')).toList();
    });

    for (int x = 0; x < leaseMap[g.lbMac]!.length; x++) {
      sbDdwrt.write(
          """${this.reformatMacForType(leaseMap[g.lbMac]![x], fileType)}=${leaseMap[g.lbHost]?[x]}=${leaseMap[g.lbIp]?[x]}=1440 """);
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
          
// there should be 3 equal signs for each lease group, if not there's a problem with the contents
      double equalMatch = ("=".allMatches(fileContents).length / 3);

      if (leaseMap['host-name']!.length != equalMatch) {
        return false;
      }

      if (g.validateLeases
          .containsBadLeases(leaseMap, g.fFormats.ddwrt.formatName)) {
        return false;
      }
      g.validateLeases
          .isLeaseMapListValid(leaseMap, g.fFormats.ddwrt.formatName);

      return true;
    } on Exception catch (e) {
      printMsg(e, errMsg: true);
      return false;
    }
  }
}
