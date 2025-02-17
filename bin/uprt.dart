// Copyright 2021 GeekVisit All rights reserved.
// Use of this source code is governed by the license in the LICENSE file.

//Follow this convention for branching:
//https://nvie.com/posts/a-successful-git-branching-model
//from feature to develop:
//https://nvie.com/posts/a-successful-git-branching-model/#incorporating-a-finished-feature-on-develop
//from develop to release:
//https://nvie.com/posts/a-successful-git-branching-model/#creating-a-release-branch
//don't rebase https://dmytrechko.com/differences-between-git-merge-and-git-rebase-dc471d84c72d
// use conventional commits:
//https://www.conventionalcommits.org/en/v1.0.0/#summary

// TODO: Add support for pihole ?
// TODO: Add support for isc-dhcp dhcpd.leases ?

import 'package:uprt/lib.dart';

void main(List<String> arguments) {
  try {
 
    // arguments = <String>[
    //    "test/test-data/*.*",
    //    "-g",
    //    "cdjmnop",
    //        "-v",
    //        "v",
    //  "-b",
    //  "example-merge",
    //       "-l",
    //        "-P",
    //        "bin/uprt.log"

    //     "test/test-data/lease-list-infile.csv",
    //     "-g",
    //     "d",
    //    "-m",
    //    "test/test-merge/dhcp.openwrt",
    //  "-d",
    //  "test/test-output",
    //     "-b",
    //     "example-merge",
    //     "-"
    //    "-w",
    //    "-a",
    //    "-s",
    //    "-z",
    //    "-P",
    //    "./uprt-p.log"
    //        "-r"

    //       "test/test-data/*file.json",
    //       "test/test-data/*file.csv",
    //        "-L",
    //       "192.168.0.1",
    //       "-H",
    //       "192.168.0.254",
    //       "-t",
    //           "c",
    //       "-b",
    //       "test-output-file",
    //       "-g",
    //       "m",

    //       "-S",
    //        "myserver",

    //       "c",
    //          "cdjnmop",

    //       "-v",
    //        "-l",
    //        "uprt-log-example.log"
    //    "-V"
    //  ];


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
