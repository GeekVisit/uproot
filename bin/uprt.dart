//Take out requirement to have hostnames and validate without
//TODO: allow new static leases to be inserted into existing pfsense/opnsense XML doc
//TODO: test directory input/outputs in production
//TODO: Delete deprecated linter

//TODO: Add test for file globs/file exists
//TODO: Test log files

import 'package:uprt/lib.dart';

void main(List<String> arguments) {
  try {
    arguments = <String>[
//       "test/test-data/*file.json",
//       "test/test-data/*file.csv",
//       // "-L",
//       "192.168.0.1",
//       "-H",
//       "192.168.0.254",
// //      "-t",
//       //    "c",
//       //"-b",
//       //"test-output-file",
//       "-g",
//       "m",
//       //  "-d",
//       //"test/test-output",
//       //"-s",
//       // "myserver",

// //      "c",
//       //   "cdjnmop",
//       "-w",
//       //"-v",
//       // "-l",
//       // "uprt-log-example.log"
      "-V"
    ];

    Converter uprt = Converter();
    uprt.convertFileList(arguments);
  } on Exception catch (e) {
    handleExceptions(e);
    // ignore: avoid_catching_errors
  } on Error catch (e) {
    displayFatalError(e);
  } finally {
    Converter.cleanUp();
  }
}
