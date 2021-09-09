import 'globals.dart' as g;
import 'ip.dart';
import 'src.dart';

class ValidateLeases {
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

  //Checks if ip is valid, within range and not a duplicate before adding
  bool isLeaseValid(Map<String, dynamic> leaseMap, int i, String fileType) {
    String macAddress = leaseMap[g.lbMac]![i], ipAddress = leaseMap[g.lbIp]![i];
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
      printMsg("$macAddress is not a valid Mac Address", errMsg: true);
      return false;
    }

    if (!ip.isIp4(ipAddress)) {
      badLeases.add("Number is Not A Valid IP 4Address: $leaseValues ");
      printMsg("IP $ipAddress is not a valid IP4 Address.", errMsg: true);
      return false;
    } else if (isDuplicate(macAddress, hostName, ipAddress)) {
      printMsg("Duplicate lease for $ipAddress.", errMsg: true);
      return false;
    }

    if ((g.argResults['ip-low-address'] != null &&
            g.argResults['ip-high-address'] != null) &&
        !ip.isWithinRange(
          ipAddress,
          g.argResults['ip-low-address'],
          g.argResults['ip-high-address'],
        )) {
      badLeases.add("IP Outside Range: $ipAddress");
      printMsg("IP out of range for $ipAddress", errMsg: true);
      return false;
    } else {
      printMsg("Both Low and High Ranges Not Given So Not Enforcing Ip Range");
    }

    addProcessedLease(macAddress, hostName, ipAddress);
    return true;
  }

  bool containsBadLeases(Map<String, List<String>> leaseMap, String fileType) {
    try {
      bool returnValue = false;
      if (areAllLeaseMapValuesEmpty(leaseMap)) {
        throw Exception("Error - no valid leases");
      }

      if (leaseMap[g.lbMac]!.length != leaseMap[g.lbIp]!.length) {
        throw Exception("Mac Addresses do not match number of ip addresses.");
      }

      for (int i = 0; i < leaseMap[g.lbMac]!.length; i++) {
        if (!g.validateLeases.isLeaseValid(leaseMap, i, fileType)) {
          returnValue = true;
        }
      }
      printBadLeases();
      return returnValue;
    } on Exception catch (e) {
      printMsg(e, errMsg: true);
      printBadLeases();
      return true;
    }
  }

  void printBadLeases() {
    if (badLeases.isNotEmpty) {
      printMsg(badLeases.join(), errMsg: true);
    }
  }

  static void initialize() {
    //set static variables to nothing
    ValidateLeases.processedMac = <String>[];
    ValidateLeases.processedName = <String>[];
    ValidateLeases.processedIp = <String>[];
    ValidateLeases.badLeases = <String>[];
  }

  Map<String, List<String>> removeBadLeases(
      Map<String, List<String>> leaseMap, String fileType) {
    try {
      if (leaseMap.isEmpty) throw Exception("Error - no valid leases");

      for (int i = 0; i < leaseMap[g.lbMac]!.length; i++) {
        if (!g.validateLeases.isLeaseValid(leaseMap, i, fileType)) {
          leaseMap.keys.forEach(((dynamic e) => leaseMap[e]!.removeAt(i)));

          continue;
        }
        return leaseMap;
      }
      return leaseMap;
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
      rethrow;
    }
  }

  //** checks if all values of Lease Map are Empty Lists */
  bool areAllLeaseMapValuesEmpty(Map<String, List<String>?> leaseMap) {
    return (leaseMap.values
            .toList()
            .fold(0, (dynamic t, dynamic e) => t + e.length)) ==
        0;
  }

  // ignore: slash_for_doc_comments
  /** Deletes bad leases, also validates lease */
  Map<String, List<String>> getValidLeaseMap(
      Map<String, List<String>> leaseMap, String fileType) {
    try {
      leaseMap = removeBadLeases(leaseMap, fileType);

      validateLeaseList(leaseMap, fileType);
      printBadLeases();
      return leaseMap;
    } on Exception {
      rethrow;
    }
  }
}

class InvalidIpAddressException implements Exception {
  String errMsg() => 'Input file contains invalid IP Addresses';
}
