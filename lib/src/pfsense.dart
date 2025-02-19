// Copyright 2021 GeekVisit All rights reserved.
// Use of this source code is governed by the license in the LICENSE file.
import 'package:xml/xml.dart';

import '../lib.dart';
import 'globals.dart' as g;

class PfSense extends FileType {
  //
  //this is the appearance of the properties in the file (Mac comes first, etc.)
  static const int macIdx = 0, hostIdx = 1, ipIdx = 2;

  String fileType = g.fFormats.pfsense.formatName;

  String preLeaseXml = '''<dhcpd>
	<lan>
		<range>
			<from></from>
			<to></to>
		</range>''';
  @override
  String genericXmlStaticMapTemplate = '''
 		<staticmap>
			<mac></mac>
			<cid></cid>
			<ipaddr></ipaddr>
			<hostname></hostname>
			<descr></descr>
			<filename></filename>
			<rootpath></rootpath>
			<defaultleasetime></defaultleasetime>
			<maxleasetime></maxleasetime>
			<gateway></gateway>
			<domain></domain>
			<domainsearchlist></domainsearchlist>
			<ddnsdomain></ddnsdomain>
			<ddnsdomainprimary></ddnsdomainprimary>
			<ddnsdomainsecondary></ddnsdomainsecondary>
			<ddnsdomainkeyname></ddnsdomainkeyname>
			<ddnsdomainkeyalgorithm>hmac-md5</ddnsdomainkeyalgorithm>
			<ddnsdomainkey></ddnsdomainkey>
			<tftp></tftp>
			<ldap></ldap>
			<nextserver></nextserver>
			<filename32></filename32>
			<filename64></filename64>
			<filename32arm></filename32arm>
			<filename64arm></filename64arm>
			<numberoptions></numberoptions>
		</staticmap>''';

  String postLeaseXml = '''
    <enable></enable>
  </lan>
</dhcpd>''';

  @override
  //Given a string this returns Maps of a list of each lease
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

      final XmlDocument pfsenseDoc = XmlDocument.parse(fileContents);

      leaseMap[g.lbMac] = pfsenseDoc
          .findAllElements('mac')
          .map((dynamic e) => e.text.toString())
          .toList();
      leaseMap[g.lbHost] = pfsenseDoc
          .findAllElements('hostname')
          .map((dynamic e) => e.text.toString())
          .toList();
      leaseMap[g.lbIp] = pfsenseDoc
          .findAllElements('ipaddr')
          .map((dynamic e) => e.text.toString())
          .toList();

      if (removeBadLeases) {
        return g.validateLeases
            .removeBadLeases(leaseMap, g.fFormats.pfsense.formatName);
      } else {
        return leaseMap;
      }
    } on XmlParserException catch (e) {
      printMsg("""
Unable to extract static leases from file, file may not be proper pfSense XML format, $e""");
      return leaseMap;
    } on Exception {
      rethrow;
    }
  }

  String build(Map<String, List<String>?> leaseMap) {
    try {
      dynamic mergeTargetFileType = (g.argResults['merge'] != null)
          ? g.cliArgs.getFormatTypeOfFile(getGoodPath(g.argResults['merge']))
          : "";

      StringBuffer sbPf = StringBuffer();

      preLeaseXml = updateXmlIpRange(preLeaseXml);

      String tmpLeaseTags;

      if (g.argResults['merge'] != null && mergeTargetFileType == "p") {
        return mergeXmlTags(leaseMap);
      }

      // fill in template for each lease map and write to tmpLeaseTags
      for (int x = 0; x < leaseMap[g.lbMac]!.length; x++) {
        sbPf.write(
            // ignore: lines_longer_than_80_chars
            "\n${fillInXmlStaticTemplate(genericXmlStaticMapTemplate, leaseMap, x)}");
      }
      tmpLeaseTags = sbPf.toString();
      sbPf.clear();
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
        throw Exception("Missing Argument for isContentValid in pfSense");
      }

      dynamic leaseMap =
          getLeaseMap(fileContents: fileContents, removeBadLeases: false);

      if (g.validateLeases
          .containsBadLeases(leaseMap, g.fFormats.pfsense.formatName)) {
        return false;
      }
      g.validateLeases
          .validateLeaseList(leaseMap, g.fFormats.pfsense.formatName);

      return true;
    } on Exception catch (e) {
      printMsg(e, errMsg: true);
      return false;
    }
  }
}
