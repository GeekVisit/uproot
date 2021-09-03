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
            """$newL $reasonFailed for lease: address=$ip mac-address=$mac name=$host""")
        : "";

    return (reasonFailed.isNotEmpty);
  }

  //Checks if ip is valid, within range and not a duplicate before adding
  bool isLeaseValid(String macAddress, String hostName, String ipAddress) {
    ValidateLeases.initialize();
    Ip ip = Ip();
    String leaseValues =
        "mac-address=$macAddress name=$hostName address=$ipAddress";

    if (!ip.isMacAddress(macAddress)) {
      printMsg("$macAddress is not a valid Mac Address", errMsg: true);
      return false;
    }

    if (!ip.isIp4(ipAddress)) {
      badLeases.add("Number is Not A Valid IP 4Address: $leaseValues ");
      printMsg("IP $ipAddress is not a valid IP4 Address.", errMsg: true);
      return false;
    } else if (!ip.isWithinRange(
      ipAddress,
      argResults['ip-low-address'],
      argResults['ip-high-address'],
    )) {
      badLeases.add("IP Outside Range: $ipAddress");
      printMsg("IP out of range for $ipAddress", errMsg: true);
      return false;
    } else if (isDuplicate(macAddress, hostName, ipAddress)) {
      printMsg("Duplicate lease for $ipAddress.", errMsg: true);
      return false;
    }

    addProcessedLease(macAddress, hostName, ipAddress);
    return true;
  }

  bool containsBadLeases(Map<String, List<String>> leaseMap) {
    try {
      bool returnValue = false;
      if (leaseMap[lbMac] == null ||
          leaseMap[lbHost] == null ||
          leaseMap[lbIp] == null) throw Exception("Error - no valid leases");

      if (leaseMap[lbMac]!.length != leaseMap[lbHost]!.length ||
          leaseMap[lbMac]!.length != leaseMap[lbIp]!.length) {
        throw Exception(
            "Mac Addresses do not match number of host names and/or ip addresses. Make sure you have a host name defined for each static lease.");
      }

      for (int i = 0; i < leaseMap[lbMac]!.length; i++) {
        if (!validateLeases.isLeaseValid(
            leaseMap[lbMac]![i], leaseMap[lbHost]![i], leaseMap[lbIp]![i])) {
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
    if (ValidateLeases.badLeases.isNotEmpty) {
      printMsg(ValidateLeases.badLeases.join(), errMsg: true);
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
      Map<String, List<String>> leaseMap) {
    if (leaseMap[lbMac] == null ||
        leaseMap[lbHost] == null ||
        leaseMap[lbIp] == null) throw Exception("Error - no valid leases");

    for (int i = 0; i < leaseMap[lbMac]!.length; i++) {
      if (!validateLeases.isLeaseValid(
          leaseMap[lbMac]![i], leaseMap[lbHost]![i], leaseMap[lbIp]![i])) {
        leaseMap[lbMac]!.removeAt(i);
        leaseMap[lbHost]!.removeAt(i);
        leaseMap[lbIp]!.removeAt(i);
        continue;
      }
    }

    return leaseMap;
  }

  bool validateLeaseList(Map<String, List<String>?> leaseMap, String fileType) {
    try {
      if (leaseMap[lbMac]!.isEmpty &&
          leaseMap[lbHost]!.isEmpty &&
          leaseMap[lbIp]!.isEmpty) {
        throw Exception(
            """File ${argResults['input-file']} is empty of Leases or is not a ${conversionTypes[inputType]} format.""");
      }
      if ((leaseMap[lbMac]?.length != leaseMap[lbHost]?.length) ||
          (leaseMap[lbMac]?.length != leaseMap[lbIp]?.length)) {
        throw Exception(
            "Corrupt $fileType file, each Lease must have a host-name, "
            "ip_address and mac-address.");
      }

      return true;
    } on Exception catch (e) {
      printMsg(e, errMsg: true);
      rethrow;
    }
  }

  //Deletes bad leases, also validates lease
  Map<String, List<String>> getValidLeaseMap(
      Map<String, List<String>> leaseMap, String fileType) {
    try {
      leaseMap = removeBadLeases(leaseMap);

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
