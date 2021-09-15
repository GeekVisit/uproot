//Take out requirement to have hostnames and validate without
//TODO: allow new static leases to be inserted into existing openwrt/ddwrt/pfsense/opnsense XML doc
// USING -M for merge
//TODO: make sure verbosity works properly
//TODO: Cleanup tests
//TODO: Delete deprecated linter

//DONE (for commit message):
// imported validators package and replaced own ip check with package method
// added hostname validation check

import 'package:uprt/lib.dart';

void main(List<String> arguments) {
  try {
    // arguments = <String>[
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
// //       //  "-d",
// //       //"test/test-output",
// //       //"-s",
// //       // "myserver",

// // //      "c",
// //       //   "cdjnmop",
// //       "-w",
// //       //"-v",
// //       // "-l",
// //       // "uprt-log-example.log"
//     //"-V"
//     ];

    Converter uprt = Converter();
    uprt.convertFileList(arguments);
  } on Exception catch (e) {
    if (testRun) handleExceptions(e);
    // ignore: avoid_catching_errors
  } on Error catch (e) {
    displayFatalError(e);
  } finally {
    Converter.cleanUp();
  }
}
