//Take out requirement to have hostnames and validate without
//TODO: allow new static leases to be inserted into existing pfsense/opnsense XML doc
//TODO: test directory input/outputs in production
//TODO: Make base name optional
//TODO: Delete deprecated linter
//TODO: Make low/high optional
//TODO: Get Rid of -i as requirement ?, require filename
//Wildcard on input not permitted - need to parse
//TODO: Test log files

import 'dart:io';
import 'package:uprt/lib.dart';

void main(List<String> arguments) {
  try {
    arguments = <String>[
      "test/test-data/*.csv",
      "-i",
      "test/test-data/lease-list-infile.csv",
      "-L",
      "192.168.0.1",
      "-H",
      "192.168.0.254",
//      "-t",
      //    "c",
      "-b",
      "test-output-file",
      "-g",
      "m",
      "-d",
      "test/test-output",
      "-s",
      //    "myserver",

//      "c",
      //   "cdjnmop",
      "-w",
      //"-v",
      // "-l",
      // "uprt-log-example.log"
    ];

    upRoot(arguments);
  } on FileSystemException catch (e) {
    displayFatalFileSystemError(e);
  } on FormatException catch (e) {
    printMsg(e.message, errMsg: true);
  } on Exception catch (e) {
    displayFatalException(e);
    // ignore: avoid_catching_errors
  } on Error catch (e) {
    displayFatalError(e);
  } finally {
    cleanUp();
  }
}
