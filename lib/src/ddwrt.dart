// Copyright 2025 GeekVisit All rights reserved.
// Use of this source code is governed by the license in the LICENSE file.

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

      List<String> lease = fileContents.split(' ');

      for (int x = 0; x < lease.length; x++) {
        List<String> leaseProperty = lease[x].split('=');

        if (leaseProperty.length < 3) {
          printMsg("Bad Lease: \"${leaseProperty.join(" ")}\" Skipping ...");
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

  @override
  String buildOutFileContents(Map<String, List<String>?> leaseMap) {
    StringBuffer sbDdwrt = StringBuffer();

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
