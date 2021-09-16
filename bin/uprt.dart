//Take out requirement to have hostnames and validate without
// USING -M for merge
//TODO: make sure verbosity works properly
//TODO: Delete deprecated linter
//TODO: Not giving error messages when options are wrong when interpreting/using dart
//TODO: (now):
//Insert into existing file for:
// .json, csv,  opn, pfs, ddwrt, openwrt, rsc,

import 'package:uprt/lib.dart';

void main(List<String> arguments) {
  try {
    arguments = <String>[
      //   "test/test-data/*.csv",
      //   "-g",
      //   "m",
      //   //   "-v",
      //   //   "v",
      //   //   "-b",
      //   //   "test-output-now",
      //   //   "-l",
      //   //   "-P",
      //   //   "bin/uprt.log"
      // ];

      "test/test-data/lease-list-bad-infile.csv",
      "-g",
      "c",
      "-m",
      "test/test-data/lease-list-infile.csv",
      "-d",
      "test/test-output",
      "-b",
      "example-merge",
      "-w",
// //       "test/test-data/*file.json",
// //       "test/test-data/*file.csv",
// //       // "-L",
// //       "192.168.0.1",
// //       "-H",
// //       "192.168.0.254",
// // //      "-t",
// //       //    "c",
// //       //"-b",
// //       //"test-output-file",
// //       "-g",
// //       "m",

// //       //"-s",
// //       // "myserver",

// // //      "c",
// //       //   "cdjnmop",

// //       //"-v",
// //       // "-l",
// //       // "uprt-log-example.log"
//     //"-V"
    ];

    Converter uprt = Converter();
    uprt.convertFileList(arguments);
  } on Exception catch (e) {
    if (!testRun) handleExceptions(e);
    // ignore: avoid_catching_errors
  } on Error catch (e) {
    displayFatalError(e);
  } finally {
    try {
      Converter.cleanUp();
    } on Exception catch (e) {
      print(e);
    }
  }
}
