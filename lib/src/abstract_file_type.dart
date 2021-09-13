// ignore: unused_import
import 'dart:io';

import 'file_ops.dart';

abstract class FileType {
  //Returns a Map of static Leases in form of

  abstract String fileType;

  String toJson();

  Map<String, List<String>?> getLeaseMap(
      {String fileContents = "", List<String> fileLines});

  //Builds file from List of leases containing mac-address,host-name, ip address
  String build(Map<String, List<String>?> deviceList, StringBuffer buildOutput);

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
            """$filePath is invalid format  for $fileType and/or has bad leases""",
            errMsg: true);
        return false;
      }
    } on Exception catch (e) {
      printMsg(e, errMsg: true);
      return false;
    }
  }
}
