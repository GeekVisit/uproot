// Copyright 2021 GeekVisit All rights reserved.
// Use of this source code is governed by the license in the LICENSE file.

import 'package:xml/xml.dart';

import '../lib.dart';
import 'globals.dart' as g;

class OpnSense extends FileType {
  //

  String preLeaseXml = '''<?xml version="1.0"?>
<opnsense>
<dhcpd>
    <lan>''';
  @override
  String genericXmlStaticMapTemplate = '''
 		      <staticmap>
        <mac></mac>
        <ipaddr></ipaddr>
        <hostname></hostname>        
      </staticmap>''';

  String postLeaseXml = '''
     </lan>  
  </dhcpd>
  </opnsense>''';

  //this is the appearance of the properties in the file (Mac comes first, etc.)
  static const int macIdx = 0, hostIdx = 1, ipIdx = 2;

  String fileType = g.fFormats.opnsense.formatName;

  @override
  //Given a string this returns Maps of the a list of each lease
  Map<String, List<String>> getLeaseMap(
      {String fileContents = "",
      List<String>? fileLines,
      bool removeBadLeases = true}) {
    //

    Map<String, List<String>> leaseMap = <String, List<String>>{
      g.lbMac: <String>[],
      g.lbHost: <String>[],
      g.lbIp: <String>[],
    };
    try {
      if (fileContents == "") {
        printMsg("Source file is empty or corrupt.", errMsg: true);
        return leaseMap;
      }

      final XmlDocument opnsenseDoc = XmlDocument.parse(fileContents);

      leaseMap[g.lbMac] = opnsenseDoc
          .findAllElements('mac')
          .map((dynamic e) => e.text.toString())
          .toList();

      leaseMap[g.lbHost] = opnsenseDoc
          .findAllElements('hostname')
          .map((dynamic e) => e.text.toString())
          .toList();
      leaseMap[g.lbIp] = opnsenseDoc
          .findAllElements('ipaddr')
          .map((dynamic e) => e.text.toString())
          .toList();

      if (removeBadLeases) {
        return g.validateLeases
            .removeBadLeases(leaseMap, g.fFormats.opnsense.formatName);
      } else {
        return leaseMap;
      }
    } on XmlParserException catch (e) {
      printMsg("""
Unable to extract static leases from file, file may not be proper OPNsense XML format, $e""");
      return leaseMap;
    } on Exception {
      rethrow;
    }
  }

  String build(Map<String, List<String>?> leaseMap) {
    try {
      StringBuffer sbOpn = StringBuffer();
      dynamic mergeTargetFileType = (g.argResults['merge'] != null)
          ? g.cliArgs.getFormatTypeOfFile(getGoodPath(g.argResults['merge']))
          : "";

      preLeaseXml = updateXmlIpRange(preLeaseXml);

      String tmpLeaseTags;
      if (g.argResults['merge'] != null && mergeTargetFileType == "p") {
        return mergeXmlTags(leaseMap);
      }

      // fill in template for each lease map and write to tmpLeaseTags
      for (int x = 0; x < leaseMap[g.lbMac]!.length; x++) {
        sbOpn.write(
            // ignore: lines_longer_than_80_chars
            "\n${fillInXmlStaticTemplate(genericXmlStaticMapTemplate, leaseMap, x)}");
      }
      tmpLeaseTags = sbOpn.toString();
      sbOpn.clear();
      return "$preLeaseXml$tmpLeaseTags\n$postLeaseXml";
    } on Exception {
      rethrow;
    }
  }

  @override
  bool isContentValid({String fileContents = "", List<String>? fileLines}) {
    try {
      ValidateLeases.clearProcessedLeases();
      if (fileContents == "") {
        throw Exception("Missing Argument for isContentValid in OpnSense");
      }

      dynamic leaseMap =
          getLeaseMap(fileContents: fileContents, removeBadLeases: false);

      if (g.validateLeases
          .containsBadLeases(leaseMap, g.fFormats.opnsense.formatName)) {
        return false;
      }
      g.validateLeases
          .validateLeaseList(leaseMap, g.fFormats.opnsense.formatName);

      return true;
    } on Exception catch (e) {
      printMsg(e, errMsg: true);
      return false;
    }
  }
}
