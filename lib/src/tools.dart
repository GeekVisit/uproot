// Copyright 2021 GeekVisit All rights reserved.
// Use of this source code is governed by the license in the LICENSE file.

import 'dart:io';

import 'ip.dart';

class Tools {
  void replaceMacsWithRandom() {}

  void replaceIp4WithRandom(String filePath) {
    Ip ip = Ip();

    String fileContents = File(filePath).readAsStringSync();

    RegExp macMatchPattern =
        RegExp(r"(?:(?:[0-9A-Fa-f]{2}(?=([-:]))(?:\1[0-9A-Fa-f]{2}){5}))");

    fileContents.replaceAll(macMatchPattern, ip.getRandomMacAddress());
  }
}

// RegExp ip4Match =
      //  RegExp(r"\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b");
  
