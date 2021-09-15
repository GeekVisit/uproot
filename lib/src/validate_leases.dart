import 'package:validators/validators.dart';

import 'globals.dart' as g;
import 'ip.dart';
import 'src.dart';

class ValidateLeases {
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
  bool isDuplicate(String mac, String host, String ip) {
    String reasonFailed;

    reasonFailed = processedMac.contains(mac)
        ? "Mac Duplicate"
        : processedName.contains(host)
            ? "Name Duplicate"
            : processedIp.contains(ip)
                ? "IP Duplicate"
                : "";

    (reasonFailed.isNotEmpty)
        ? badLeases.add(
            """${g.newL} $reasonFailed for lease: address=$ip mac-address=$mac name=$host""")
        : "";

    return (reasonFailed.isNotEmpty);
  }

  /* Checks Validity of Mac, Ip, and Hostname for a particular lease */
  bool isLeaseValid(Map<String, dynamic> leaseMap, int i, String fileType) {
    try {
      String macAddress = leaseMap[g.lbMac]![i],
          ipAddress = leaseMap[g.lbIp]![i];
      String hostName;
      if (fileType != g.fFormats.mikrotik.formatName &&
          i < leaseMap[g.lbHost].length) {
        hostName = leaseMap[g.lbHost]![i];
      } else {
        hostName = "";
      }

      ValidateLeases.initialize();
      Ip ip = Ip();
      String leaseValues = "mac-address=$macAddress address=$ipAddress";

      if (!ip.isMacAddress(macAddress)) {
        badLeases.add("$macAddress is not a valid Mac Address");
        //   printMsg("$macAddress is not a valid Mac Address", errMsg: true);
      }

      if (hostName != "" && !isFQDN(hostName, requireTld: false)) {
        badLeases.add("Hostname is Not A Valid Host Name: $leaseValues ");
      }

      if (!isIP(ipAddress, 4)) {
        badLeases.add("Number is Not A Valid IP 4 Address: $leaseValues ");
        // printMsg("IP $ipAddress is not a valid IP4 Address.", errMsg: true);
      }

      if (isDuplicate(macAddress, hostName, ipAddress)) {
        badLeases.add("Duplicate lease for $ipAddress");
        //printMsg("Duplicate lease for $ipAddress.", errMsg: true);
      }

      if ((g.argResults['ip-low-address'] != null &&
              g.argResults['ip-high-address'] != null) &&
          !ip.isWithinRange(
            ipAddress,
            g.argResults['ip-low-address'],
            g.argResults['ip-high-address'],
          )) {
        badLeases.add("IP Outside Range: $ipAddress");
        //printMsg("IP out of range for $ipAddress", errMsg: true);
        return false;
      } else if (!printedLowHighRangeWarning) {
        printMsg("Both Low and High Ranges Not Given So Not Enforcing Ip Range",
            onlyIfVerbose: true);
        printedLowHighRangeWarning = true;
      }

      if (badLeases.isNotEmpty) {
        return false;
      }

      addProcessedLease(macAddress, hostName, ipAddress);
      return true;
    } on Exception {
      return false;
    }
  }

  bool containsBadLeases(Map<String, List<String>> leaseMap, String fileType) {
    try {
      if (areAllLeaseMapValuesEmpty(leaseMap)) {
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
      printMsg(badLeases.join(), errMsg: true);
    }
  }

  /* Initializes Static Properties */
  static void initialize() {
    //set static variables to nothing
    ValidateLeases.processedMac = <String>[];
    ValidateLeases.processedName = <String>[];
    ValidateLeases.processedIp = <String>[];
    ValidateLeases.badLeases = <String>[];
  }

  Map<String, List<String>> getGoodLeaseMap(
      Map<String, List<String>> rawLeaseMap, String fileType) {
    Map<String, List<String>> goodLeaseMap = <String, List<String>>{
      g.lbMac: <String>[],
      g.lbHost: <String>[],
      g.lbIp: <String>[],
    };

    int totalBadLeases = 0;
    try {
      if (areAllLeaseMapValuesEmpty(rawLeaseMap)) {
        printMsg("Error - no valid leases in file.");
        return rawLeaseMap;
      }

      for (int i = 0; i < rawLeaseMap[g.lbMac]!.length; i++) {
        if (g.validateLeases.isLeaseValid(rawLeaseMap, i, fileType)) {
          goodLeaseMap[g.lbMac]!.add(rawLeaseMap[g.lbMac]![i].trim());

          (fileType == "Mikrotik")
              ? goodLeaseMap[g.lbHost]!.add("")
              : goodLeaseMap[g.lbHost]!.add(rawLeaseMap[g.lbHost]![i].trim());

          goodLeaseMap[g.lbIp]!.add(rawLeaseMap[g.lbIp]![i].trim());

          //  continue;
        } else {
          totalBadLeases++;
          print(
              // ignore: lines_longer_than_80_chars
              "Excluding invalid lease from output file (total bad leases: $totalBadLeases): "
              """
${rawLeaseMap[g.lbMac]![i]} ${rawLeaseMap[g.lbHost]![i]}, ${rawLeaseMap[g.lbIp]![i]}""");
        }
      }
      return goodLeaseMap;
    } on Exception {
      rethrow;
    }
  }

  bool validateLeaseList(Map<String, List<String>?> leaseMap, String fileType) {
    try {
      // if all of lists in leaseMap entries are empty, i.e., have 0 length
      if (areAllLeaseMapValuesEmpty(leaseMap)) {
        throw Exception(
            """File ${g.inputFile} is empty of Leases or is not a ${g.conversionTypes[g.inputType]} format.""");
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

class InvalidIpAddressException implements Exception {
  String errMsg() => 'Input file contains invalid IP Addresses';
}
