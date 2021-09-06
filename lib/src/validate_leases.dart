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
  bool isLeaseValid(Map<String, dynamic> leaseMap, int i, String fileType) {
    String macAddress = leaseMap[lbMac]![i], ipAddress = leaseMap[lbIp]![i];
    String hostName;
    if (fileType != fFormats.mikrotik.formatName) {
      hostName = leaseMap[lbHost]![i];
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

  bool containsBadLeases(Map<String, List<String>> leaseMap, String fileType) {
    try {
      bool returnValue = false;
      if (leaseMap.isEmpty) throw Exception("Error - no valid leases");

      if (leaseMap[lbMac]!.length != leaseMap[lbIp]!.length) {
        throw Exception("Mac Addresses do not match number of ip addresses.");
      }

      for (int i = 0; i < leaseMap[lbMac]!.length; i++) {
        if (!validateLeases.isLeaseValid(leaseMap, i, fileType)) {
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
      Map<String, List<String>> leaseMap, String fileType) {
    try {
      if (leaseMap.isEmpty) throw Exception("Error - no valid leases");

      for (int i = 0; i < leaseMap[lbMac]!.length; i++) {
        if (!validateLeases.isLeaseValid(leaseMap, i, fileType)) {
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
      if (leaseMap.isEmpty) {
        throw Exception(
            """File ${argResults['input-file']} is empty of Leases or is not a ${conversionTypes[inputType]} format.""");
      }
      if ((leaseMap[lbMac]?.length != leaseMap[lbIp]?.length)) {
        throw Exception("Corrupt $fileType file, each Lease must have an "
            "ip address and mac address.");
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
