//Try to follow this convention:

//https://nvie.com/posts/a-successful-git-branching-model

//Take out requirement to have hostnames and validate without
// USING -M for merge
//TODO: make sure verbosity works properly
//TODO: Delete deprecated linter
//TODO: Not giving error messages when options are wrong when interpreting/using dart
//TODO: do away with use of temporary json file and convert directly
//TODO: (now):
//TODO: Ignore -g for merge - always m
//Insert into existing file for:
// .json, csv,  opn, pfs, ddwrt, openwrt, rsc,

//TODO: allow new static leases to be inserted into existing pfsense XML doc

import 'package:uprt/lib.dart';

void main(List<String> arguments) {
  try {
    arguments = <String>[
      "test/test-data/lease-list-infile.csv",
      "-g",
      "n",
//       //   "-v",
//       //   "v",
      "-b",
      "example-merge",
      //   "-l",
//       //   "-P",
//       //   "bin/uprt.log"

//       "test/test-data/lease-list-infile.csv",
//       "-g",
//       "d",
      "-m",
      "test/test-merge/lease-list-infile-merge-opn.xml",
      "-d",
      "test/test-output",
//       "-b",
//       "example-merge",
//       //"-
      "-w",
      // "-a",
      "-s",
//       "-r"

// // //       "test/test-data/*file.json",
// // //       "test/test-data/*file.csv",
// // //       // "-L",
// // //       "192.168.0.1",
// // //       "-H",
// // //       "192.168.0.254",
// // // //      "-t",
// // //       //    "c",
// // //       //"-b",
// // //       //"test-output-file",
// // //       "-g",
// // //       "m",

// // //       //"-S",
// // //       // "myserver",

// // // //      "c",
// // //       //   "cdjnmop",

// // //       //"-v",
// // //       // "-l",
// // //       // "uprt-log-example.log"
// //     //"-V"
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
