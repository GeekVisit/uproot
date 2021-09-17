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
      return (isContentValid(fileContents: File(filePath).readAsStringSync()));
    } on Exception catch (e) {
      if (g.testRun) {
        rethrow;
      } else {
        printMsg(e, errMsg: true);
        return false;
      }
    }
  }
}
