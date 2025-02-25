// Copyright 2025 GeekVisit All rights reserved.
// Use of this source code is governed by the license in the LICENSE file.

import 'package:validators/validators.dart';

import '../lib.dart';
import 'globals.dart' as g;

class ValidateLeases {
  static bool blnRequireTld = false;
  static bool printedLowHighRangeWarning = false;
  static List<String> processedMac = <String>[],
      processedIp = <String>[],
      processedName = <String>[],
      badLeases = <String>[];

  String test = "";

  void addProcessedLease(String macAddress, String hostName, String ipAddress) {
    processedMac.add(macAddress);
    processedName.add(hostName);
    processedIp.add(ipAddress);
  }

/* Check if already processed, if so mark as duplicate */
  bool isDuplicate(String mac, String host, String ip, StringBuffer sb) {
    String reasonFailed;

    reasonFailed = processedMac.contains(mac)
        ? "Mac Duplicate"
        : processedName.contains(host) && host != ""
            ? "Name Duplicate"
            : processedIp.contains(ip)
                ? "IP Duplicate"
                : "";

    (reasonFailed.isNotEmpty)
        ? sb.write("${(sb.isNotEmpty) ? "," : ""}$reasonFailed")
        : "";

    return (reasonFailed.isNotEmpty);
  }

  /* Checks Validity of Mac, Ip, and Hostname for a particular lease */
  bool isLeaseValid(Map<String, dynamic> leaseMap, int i, String fileType) {
    try {
      String macAddress = leaseMap[g.lbMac]![i],
          ipAddress = leaseMap[g.lbIp]![i];
      String hostName;
      StringBuffer badLeaseBuffer = StringBuffer();
      bool leaseIsValid = true;

      if (fileType != g.fFormats.mikrotik.formatName &&
          i < leaseMap[g.lbHost].length) {
        hostName = leaseMap[g.lbHost]![i];
      } else {
        hostName = "";
      }

      Ip ip = Ip();

      if (!ip.isMacAddress(macAddress, g.macDelimiter[fileType]!)) {
        badLeaseBuffer.write(
            "${(badLeaseBuffer.isNotEmpty) ? "," : ""}Mac Address Not Valid");
        leaseIsValid = false;
      }

//requires tld if -fqdn argument is set

      if (hostName != "" && !doesHostMeetFqdnReqts(hostName)) {
        var failMessage =
            "Host Name ${hostName} Does Not Meet FQDN Requirements - check the -fqdn option";
        badLeaseBuffer
            .write("${(badLeaseBuffer.isNotEmpty) ? "," : ""} ${failMessage}");
        leaseIsValid = false;
      }

      if (!isIP(ipAddress, 4)) {
        badLeaseBuffer.write(
            "${(badLeaseBuffer.isNotEmpty) ? "," : ""}ip4 Address Not Valid");
        leaseIsValid = false;
      }

      if (isDuplicate(macAddress, hostName, ipAddress, badLeaseBuffer)) {
        leaseIsValid = false;
      }

      if ((g.argResults['ip-low-address'] != null &&
              g.argResults['ip-high-address'] != null) &&
          !ip.isWithinRange(
            ipAddress,
            g.argResults['ip-low-address'],
            g.argResults['ip-high-address'],
          )) {
        badLeaseBuffer.write("${(badLeaseBuffer.isNotEmpty) ? "," : ""}"
            "ip Address Outside Range");
        leaseIsValid = false;
      } else if (!printedLowHighRangeWarning) {
        printMsg("Both Low and High Ranges Not Given So Not Enforcing Ip Range",
            onlyIfVerbose: true);
        printedLowHighRangeWarning = true;
      }

      if (badLeaseBuffer.isNotEmpty) {
        badLeases.add("$macAddress, $hostName, $ipAddress "
            "(${badLeaseBuffer.toString()})");
        badLeaseBuffer.clear();
      }
      addProcessedLease(macAddress, hostName, ipAddress);
      return leaseIsValid;
    } on Exception {
      return false;
    }
  }

  bool containsBadLeases(Map<String, List<String>> leaseMap, String fileType) {
    ValidateLeases.clearProcessedLeases();
    try {
      if (areAllLeaseMapValuesEmpty(leaseMap)) {
        printMsg("Source file is corrupt - unable to extract static leases.");
        return true;
      }

      if (leaseMap[g.lbMac]!.length != leaseMap[g.lbIp]!.length) {
        printMsg(
            // ignore: lines_longer_than_80_chars
            "File is Corrupt - Mac Addresses do not match number of ip addresses.");
        return true;
      }

      for (int i = 0; i < leaseMap[g.lbMac]!.length; i++) {
        if (!g.validateLeases.isLeaseValid(leaseMap, i, fileType)) {
          printBadLeases();
          return true;
        }
      }
      printBadLeases();
      return false;
    } on Exception {
      printBadLeases();
      return true;
    }
  }

  void printBadLeases() {
    if (badLeases.isNotEmpty) {
      printMsg("Error - Bad Leases: ${badLeases.join()}", errMsg: true);
    }
  }

  /* Clear Bad and Processed Leases */
  static void clearProcessedLeases() {
    //set static variables to nothing
    ValidateLeases.processedMac = <String>[];
    ValidateLeases.processedName = <String>[];
    ValidateLeases.processedIp = <String>[];
    ValidateLeases.badLeases = <String>[];
  }

  Map<String, List<String>> removeBadLeases(
      Map<String, List<String>> rawLeaseMap, String fileType) {
    Map<String, List<String>> goodLeaseMap = <String, List<String>>{
      g.lbMac: <String>[],
      g.lbHost: <String>[],
      g.lbIp: <String>[],
    };
    ValidateLeases.clearProcessedLeases();
    int totalBadLeases = 0;
    try {
      if (areAllLeaseMapValuesEmpty(rawLeaseMap)) {
        printMsg("Error - no valid leases in source file.");
        return rawLeaseMap;
      }

      for (int i = 0; i < rawLeaseMap[g.lbMac]!.length; i++) {
        if (g.validateLeases.isLeaseValid(rawLeaseMap, i, fileType)) {
          goodLeaseMap[g.lbMac]!.add(rawLeaseMap[g.lbMac]![i].trim());

          goodLeaseMap[g.lbHost]!.add(rawLeaseMap[g.lbHost]![i].trim());

          goodLeaseMap[g.lbIp]!.add(rawLeaseMap[g.lbIp]![i].trim());

          //  continue;
        } else {
          printMsg(

              // ignore: lines_longer_than_80_chars
              " ${g.colorWarning}Excluding lease from target file (total excluded: ${totalBadLeases + 1}): ${badLeases[totalBadLeases]}${g.ansiFormatEnd}");
          totalBadLeases++;
        }
      }

      (totalBadLeases == rawLeaseMap[g.lbMac]!.length)
          ? throw Exception(
              """Unable to generate target format file, source file format is corrupt or all of its static leases are invalid.""")
          : printMsg(
              "Finished validating leases, found ${rawLeaseMap[g.lbMac]!.length - totalBadLeases}/${rawLeaseMap[g.lbMac]!.length} valid leases.");

      ValidateLeases.clearProcessedLeases();

      return goodLeaseMap;
    } on Exception catch (e) {
      if (e.toString().contains("Unable to generate target format")) {
        printMsg(e, errMsg: true);
        return goodLeaseMap;
      }

      rethrow;
    }
  }

  /// Validates the lease map list for the given file type.
  ///
  /// This function checks if the provided lease map is valid by ensuring that:
  /// 1. The lease map is not empty.
  /// 2. Each lease has the same number of IP addresses and MAC addresses.
  ///
  /// If the lease map is invalid, an exception is thrown with an appropriate
  /// error message, and the function returns `false`. If the lease map is valid,
  /// the function returns `true`.
  ///
  /// - Parameters:
  ///   - leaseMap: A map where the keys are strings and the values are lists of
  ///     strings representing the leases.
  ///   - fileType: A string representing the type of the file being validated.
  ///
  /// - Returns: A boolean value indicating whether the lease map list is valid.
  ///
  /// - Throws: An [Exception] if the lease map is empty or if any lease does not
  ///   have both an IP address and a MAC address.

  bool isLeaseMapListValid(
      Map<String, List<String>?> leaseMap, String fileType) {
    try {
      // if all of lists have 0 length throw error
      if (areAllLeaseMapValuesEmpty(leaseMap)) {
        throw Exception(
            """File ${g.inputFile} is empty of Leases or is not a ${g.typeOptionToName[g.inputType]} format.""");
      }
      if ((leaseMap[g.lbMac]?.length != leaseMap[g.lbIp]?.length)) {
        throw Exception("Corrupt $fileType file, each Lease must have an "
            "ip address and mac address.");
      }

      return true;
    } on Exception catch (e) {
      printMsg(e, errMsg: true);
      return false;
    }
  }

  //** checks if all values of Lease Map are Empty Lists */
  bool areAllLeaseMapValuesEmpty(Map<String, List<String>?> leaseMap) {
    return (leaseMap.values
            .toList()
            .fold(0, (dynamic t, dynamic e) => t + e.length)) ==
        0;
  }
}

doesHostMeetFqdnReqts(String hostName) {
  bool requiresTLD = g.argResults['fqdn'] == 'strict';
  bool allowsUnderScores = g.argResults['fqdn'] == 'relaxed';

  bool result = true;
  if (g.argResults['fqdn'] == null) return result;

  return isHostFQDN(hostName,
      requireTld: requiresTLD, allowUnderscores: allowsUnderScores);
}

class InvalidIpAddressException implements Exception {
  String errMsg() => 'Input file contains invalid IP Addresses';
}

bool isHostFQDN(String str,
    {bool requireTld = true, bool allowUnderscores = false}) {
  var parts = str.split('.');
  if (requireTld) {
    var tld = parts.removeLast();
    if (parts.length == 0 || !new RegExp(r'^[a-z]{2,}$').hasMatch(tld)) {
      return false;
    }
  }

  for (var part in parts) {
    if (!allowUnderscores) {
      if (part.contains('_')) {
        return false;
      }
    }
    if (!new RegExp(r'^[a-zA-Z0-9\u00a1-\uffff-_]+$').hasMatch(part)) {
      return false;
    }
    if (part[0] == '-' ||
        part[part.length - 1] == '-' ||
        part.indexOf('---') >= 0) {
      return false;
    }
  }
  return true;
}
