//Follow this convention for branching:
//https://nvie.com/posts/a-successful-git-branching-model

//TODO: make sure verbosity works properly

import 'package:uprt/lib.dart';
import 'package:uprt/src/globals.dart' as g;

void main(List<String> arguments) {
  try {
//     arguments = <String>[
//       "test/test-data/lease-list-infile.csv",
//       "-g",
//       "o",
// //       //   "-v",
// //       //   "v",
//       "-b",
//       "example-merge",
//       //   "-l",
// //       //   "-P",
// //       //   "bin/uprt.log"

// //       "test/test-data/lease-list-infile.csv",
// //       "-g",
// //       "d",
//       "-m",
//       "test/test-merge/dhcp.openwrt",
//       "-d",
//       "test/test-output",
// //       "-b",
// //       "example-merge",
// //       //"-
//       "-w",
//       //"-a",
//       "-s",
//       "-z",
//       "-P",
//       "./uprt-p.log"
//           "-r"

// // // //       "test/test-data/*file.json",
// // // //       "test/test-data/*file.csv",
// // // //       // "-L",
// // // //       "192.168.0.1",
// // // //       "-H",
// // // //       "192.168.0.254",
// // // // //      "-t",
// // // //       //    "c",
// // // //       //"-b",
// // // //       //"test-output-file",
// // // //       "-g",
// // // //       "m",

// // // //       //"-S",
// // // //       // "myserver",

// // // // //      "c",
// // // //       //   "cdjnmop",

// // // //       //"-v",
// // // //       // "-l",
// // // //       // "uprt-log-example.log"
// // //     //"-V"
//     ];

    Converter uprt = Converter();
    uprt.convertFileList(arguments);
  } on Exception catch (e) {
    if (!g.testRun) handleExceptions(e);
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
