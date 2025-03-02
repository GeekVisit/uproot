// Copyright 2025 GeekVisit All rights reserved.
// Use of this source code is governed by the license in the LICENSE file.



// TODO: Add support for isc-dhcp dhcpd.leases ?

import 'package:uprt/lib.dart';

void main(List<String> arguments) {
  try {
    // arguments = <String>[
    //   "test/test-data/dhcp-static-leases-rsc.txt",
    //   "-t",
    //   "m",
    //   "-g",
    //   "m",
    //   "-b",
    //   "test-output-new-rsc",
    //   "-d",
    //   "test/test-output",
    //   "-w"
    // ];

    Converter uprt = Converter();
    uprt.convertFileList(arguments);
  } on Exception catch (e) {
    handleExceptions(e);
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
