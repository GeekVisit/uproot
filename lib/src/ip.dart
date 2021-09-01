import 'dart:math';

import 'file_ops.dart';

class Ip {
  int ipStrToNum(String ip) {
    try {
      if (!isIp4(ip)) throw Exception("$ip is Not an ip4 Address.");
      return int.parse(ip
          .split(".")
          .map((dynamic d) => ('000$d'.substring('000$d'.length - 3)))
          .toList()
          .join(""));
    } on Exception {
      rethrow;
    }
  }

  bool isIp4(String ip) {
    try {
      Uri.parseIPv4Address(ip);
      return true;
    } on FormatException {
      return false;
    } on Exception {
      return false;
    }
  }

  //isMac, see https://stackoverflow.com/a/52970004/2205849

  bool isMacAddress(String mac) {
    RegExp regExp =
        RegExp(r"(?:(?:[0-9A-Fa-f]{2}(?=([-:]))(?:\1[0-9A-Fa-f]{2}){5}))");
    return regExp.hasMatch(mac);
  }

  bool isWithinRange(String address, String dotRangeMin, String dotRangeMax) {
    try {
      int rangeMin = ipStrToNum(dotRangeMin);
      int rangeMax = ipStrToNum(dotRangeMax);
      int numAddress = ipStrToNum(address);

      if (!isIp4(address) | !isIp4(dotRangeMin) | !isIp4(dotRangeMin)) {
        printMsg(
            "IP Range Check Failed - not a valid ipv4 address: IP: "
            "$address Range: $dotRangeMin - $dotRangeMax).",
            errMsg: true);
        return false;
      }

      return (numAddress >= rangeMin) && (numAddress <= rangeMax);
    } on Exception catch (e) {
      printMsg(e, errMsg: true);
      return false;
    }
  }

  String getRandomMacAddress() {
    String mac = "";
    Random r = Random();
    for (int i = 0; i < 6; i++) {
      String n = r.nextInt(255).toRadixString(16);
      if (n.length < 2) n += "0";
      mac += ":$n";
    }
    String returnVal = mac.toUpperCase().replaceFirst(RegExp(r'\:.'), "0");
    //print(returnVal);
    return returnVal;
  }
}
