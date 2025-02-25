// Copyright 2025 GeekVisit All rights reserved.
// Use of this source code is governed by the license in the LICENSE file.

import '../lib.dart';
import 'globals.dart' as g;

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

      if (fileContents == "") {
        printMsg("Source file is empty or corrupt.", errMsg: true);
        return leaseMap;
      }

      fileLines = fileContents.split("\n");

      /// Parses lines from a file to extract IP addresses, MAC addresses, and host names,
      /// and adds them to the `leaseMap`.
      ///
      /// Each line is expected to contain an IP address, MAC address, and host name in the
      /// following formats:
      /// - IP address: `address=xxx.xxx.xxx.xxx`
      /// - MAC address: `mac-address=xx:xx:xx:xx:xx:xx`
      /// - Host name: `host-name=hostname`
      ///
      /// If a host name is not found, the MAC address with colons replaced by hyphens is used as the host name.
      ///
      /// The extracted values are added to the `leaseMap` under the keys `g.lbIp`, `g.lbMac`, and `g.lbHost`.
      ///
      /// - Parameters:
      ///   - fileLines: A list of strings representing lines from the file.
      ///   - leaseMap: A map where the extracted values will be added.
      ///   - g.lbIp: The key for storing IP addresses in the `leaseMap`.
      ///   - g.lbMac: The key for storing MAC addresses in the `leaseMap`.
      ///   - g.lbHost: The key for storing host names in the `leaseMap`.
      for (var line in fileLines) {
        final ipMatch = RegExp(r'\saddress\s*=\s*((?:\d{1,3}\.){3}\d{1,3})')
            .firstMatch(line);
        final macMatch =
            RegExp(r'mac-address=(([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2}))')
                .firstMatch(line);
        final hostMatch = RegExp(r'host-name=([\w\-\.]+)').firstMatch(line);

        //skip lines that don't have ip or mac addresses
        if (ipMatch == null || macMatch == Null) {
          continue;
        }

        final ip = ipMatch.group(1) ?? '';
        final mac = macMatch?.group(1) ?? '';
        final host = hostMatch?.group(1) ?? mac.replaceAll(':', '-');

        leaseMap[g.lbIp]!.add(ip);
        leaseMap[g.lbMac]!.add(mac);
        leaseMap[g.lbHost]!.add(host);
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

  @override
  String buildOutFileContents(Map<String, List<String>?> leaseMap) {
    StringBuffer sbMikrotik = StringBuffer();
    for (int x = 0; x < leaseMap[g.lbMac]!.length; x++) {
      sbMikrotik.write(
          """\nadd mac-address=${this.reformatMacForType(leaseMap[g.lbMac]![x], fileType)} address=${leaseMap[g.lbIp]?[x]} server=${g.argResults['server']}""");
    }
    return "/ip dhcp-server lease\n${sbMikrotik.toString().trim()}";
  }

  @override
  bool isContentValid({String fileContents = "", List<String>? fileLines}) {
    try {
      ValidateLeases.clearProcessedLeases();
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
          .isLeaseMapListValid(leaseMap, g.fFormats.mikrotik.formatName);

      return true;
    } on Exception catch (e) {
      printMsg(e, errMsg: true);
      return false;
    }
  }

  //
}
