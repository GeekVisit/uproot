// Copyright 2025 GeekVisit All rights reserved.
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
    arguments = <String>[
      "test/test-data/lease-list-infile.json",
      "-t",
      "j",
      "-g",
      "h",
      "-b",
      "test-output-file",
      "-d",
      "test/test-output",
      "-w"
    ];

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
