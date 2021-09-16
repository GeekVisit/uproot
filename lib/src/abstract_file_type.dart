// ignore: unused_import
import 'dart:io';

import '../lib.dart';
import 'globals.dart' as g;

abstract class FileType {
  //Returns a Map of static Leases in form of

  abstract String fileType;

  String toTmpJson() {
    String inFileContents = File(g.inputFile).readAsStringSync();

    Map<String, List<String>> deviceList =
        getLeaseMap(fileContents: inFileContents);

    return !g.validateLeases.areAllLeaseMapValuesEmpty(deviceList)
        ? Json().build(deviceList)
        : "";
  }

// ignore: slash_for_doc_comments
/** Gets Map of Static Leases from file contents
   Removes Bad Leases by Default */
  Map<String, List<String>> getLeaseMap(
      {String fileContents = "",
      List<String> fileLines,
      bool removeBadLeases = true});

  //Builds file from List of leases containing mac-address,host-name, ip address
  String build(Map<String, List<String>?> deviceList);

//Verify whether string is a valid format
  bool isContentValid({String fileContents = "", List<String> fileLines});

//Verify whether file is a valid configuration file for format
  bool isFileValid(String filePath) {
    try {
      if (isContentValid(fileContents: File(filePath).readAsStringSync())) {
        printMsg("""$filePath is valid format for $fileType""",
            onlyIfVerbose: true);
        return true;
      } else {
        printMsg(
            """$filePath is invalid format for $fileType and/or has bad leases""",
            errMsg: true);
        return false;
      }
    } on Exception catch (e) {
      printMsg(e, errMsg: true);
      return false;
    }
  }

  // ignore: slash_for_doc_comments
  /** Merge Lease Map with Map of A Second File (Merge File Target)
   * In case of conflict of Macs or host name, the lease with the lesser ip 
   * controls, if same ip, then the one in the mergeTarget file 
   * is replaced with 
   * the lease for that ip in the input file
   * 
   * Returns Lease Map of Merge
   */
  Map<String, List<String>> mergeLeaseMapWithFile(
      Map<String, List<String>> inputFileLeaseMap, String mergeTargetPath) {
    Map<String, List<String>> mergeTargetLeaseMap = <String, List<String>>{
      g.lbMac: <String>[],
      g.lbHost: <String>[],
      g.lbIp: <String>[],
    };

    dynamic mergeTargetFileType =
        g.typeOptionToName[g.cliArgs.getFormatTypeOfFile(mergeTargetPath)];

    printMsg("Processing merge file $mergeTargetPath ...");
    mergeTargetLeaseMap = mergeLeaseMaps(inputFileLeaseMap,
        getLeaseMap(fileContents: File(mergeTargetPath).readAsStringSync()));

    /* Remove duplicate lease **/
    return validateLeases.removeBadLeases(
        mergeTargetLeaseMap, mergeTargetFileType);
  }

  // ignore: slash_for_doc_comments
  /**  Merges two LeaseMaps, optionally sorts them 
    Second LeaseMap takes precedence  */

  Map<String, List<String>> mergeLeaseMaps(
      Map<String, List<String>> leaseMap1, Map<String, List<String>> leaseMap2,
      {bool sort = true}) {
    try {
      List<String> leaseList1 = flattenLeaseMap(leaseMap1, sort: sort);
      List<String> leaseList2 = flattenLeaseMap(leaseMap2, sort: sort);
      leaseList1.addAll(leaseList2);
      if (sort) leaseList1.sort();
      return explodeLeaseList(leaseList1);
    } on Exception {
      rethrow;
    }
  }

  // ignore: slash_for_doc_comments
  /** Takes List created by flattenLeaseMap and returns LeaseMap  
  */

  Map<String, List<String>> explodeLeaseList(List<String> leaseList) {
    Map<String, List<String>> leaseMap = <String, List<String>>{
      g.lbMac: <String>[],
      g.lbHost: <String>[],
      g.lbIp: <String>[],
    };

    for (String eachLease in leaseList) {
      List<String> tmpLease = eachLease.split("|");
      leaseMap[g.lbIp]!.add(tmpLease[3]);
      leaseMap[g.lbMac]!.add(tmpLease[1]);
      leaseMap[g.lbHost]!.add(tmpLease[2]);
    }
    return leaseMap;
  }

/* Converts LeaseMap to a LeaseList consisting of long strings, each 
string consisting of fields separated by |. 
4 Fields in string: IP converted to a normalized number string, mac, host,
 and ip address. 
Strings are sorted on first field
*/
  List<String> flattenLeaseMap(Map<String, List<String>> leaseMap,
      {bool sort = true}) {
    Ip ip = Ip();
    List<String> leaseList = <String>[];
    for (int i = 0; i < leaseMap[g.lbMac]!.length; i++) {
      leaseList.add("${ip.ipStrToNum(leaseMap[g.lbIp]![i]).toString()}|"
          "${leaseMap[g.lbMac]![i]}|"
          "${leaseMap[g.lbHost]![i]}|"
          "${leaseMap[g.lbIp]![i]}");
    }
    if (sort) leaseList.sort();
    return leaseList;
  }

  // ignore: slash_for_doc_comments
  /** Merges devicelist with leases in file set with merge (-m) option
   * In case of conflict of Macs or host name, the lease with the lesser ip 
   * controls, if same ip, then the input file controls
   */
  Map<String, List<String>> mergeIfOpted(Map<String, List<String>> deviceList) {
    if (g.argResults['merge'] != null) {
      deviceList = <String, List<String>>{
        ...mergeLeaseMapWithFile(deviceList, getGoodPath(g.argResults['merge']))
      };
    }
    return deviceList;
  }
}
