import 'dart:io';

import 'package:xml/xml.dart';
import 'globals.dart' as g;
import 'src.dart';

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

  String staticMapTemplate = '''
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

    try {
      if (fileContents == "") {
        throw Exception("Missing Argument for getLeaseMap in pfSense");
      }

      final XmlDocument pfsenseDoc = XmlDocument.parse(fileContents);

      Map<String, List<String>> leaseMap = <String, List<String>>{
        g.lbMac: <String>[],
        g.lbHost: <String>[],
        g.lbIp: <String>[],
      };

      leaseMap[g.lbMac] = pfsenseDoc
          .findAllElements('mac')
          .map((dynamic e) => e.innerText.toString())
          .toList();
      leaseMap[g.lbHost] = pfsenseDoc
          .findAllElements('hostname')
          .map((dynamic e) => e.innerText.toString())
          .toList();
      leaseMap[g.lbIp] = pfsenseDoc
          .findAllElements('ipaddr')
          .map((dynamic e) => e.innerText.toString())
          .toList();

      if (removeBadLeases) {
        return g.validateLeases
            .removeBadLeases(leaseMap, g.fFormats.pfsense.formatName);
      } else {
        return leaseMap;
      }
    } on Exception catch (e) {
      printMsg(e, errMsg: true);

      rethrow;
    }
  }

  String build(Map<String, List<String>?> leaseMap) {
    try {
      dynamic mergeTargetFileType = (g.argResults['merge'] != null)
          ? g.cliArgs.getFormatTypeOfFile(getGoodPath(g.argResults['merge']))
          : "";

      StringBuffer sbPf = StringBuffer();

      preLeaseXml = updateIpRange(preLeaseXml);

      String tmpLeaseTags;

      if (g.argResults['merge'] != null && mergeTargetFileType == "p") {
        return mergePfs(leaseMap);
      }

      // fill in template for each lease map and write to tmpLeaseTags
      for (int x = 0; x < leaseMap[g.lbMac]!.length; x++) {
        sbPf.write("\n${fillInStaticTemplate(staticMapTemplate, leaseMap, x)}");
      }
      tmpLeaseTags = sbPf.toString();
      sbPf.clear();
      return "$preLeaseXml$tmpLeaseTags\n$postLeaseXml";
    } on Exception {
      rethrow;
    }
  }

  String updateIpRange(String preLeaseXml) {
    if (g.argResults['ip-low-address'] != null &&
        g.argResults['ip-high-address'] != null) {
      preLeaseXml = preLeaseXml.replaceAll(
          "<from></from>", "<from>${g.argResults['ip-low-address']}</from>");
      preLeaseXml = preLeaseXml.replaceAll(
          "<to></to>", "<to>${g.argResults['ip-high-address']}</to>");
    }
    return preLeaseXml;
  }

  String fillInStaticTemplate(
      String tmpLeaseTags, Map<String, List<String>?> leaseMap, int x) {
    tmpLeaseTags = tmpLeaseTags.replaceAll(
        "<mac></mac>", "<mac>${leaseMap[g.lbMac]![x]}</mac>");
    tmpLeaseTags = tmpLeaseTags.replaceAll("<hostname></hostname>",
        "<hostname>${leaseMap[g.lbHost]![x]}</hostname>");
    tmpLeaseTags = tmpLeaseTags.replaceAll(
        "<ipaddr></ipaddr>", "<ipaddr>${leaseMap[g.lbIp]![x]}</ipaddr>");
    return tmpLeaseTags;
  }

  @override
  bool isContentValid({String fileContents = "", List<String>? fileLines}) {
    try {
      ValidateLeases.clearProcessedLeases();
      if (fileContents == "") {
        throw Exception("Missing Argument for getLease");
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

  // ignore: slash_for_doc_comments
  /**  Keeps and updates existing lease in PFS merge file
   *  Adds new ones from input. 
  */
  String mergePfs(Map<String, List<String>?> leaseMap) {
    StringBuffer sb = StringBuffer();

    String mergeFileContents = File(g.argResults['merge']).readAsStringSync();
    //final XmlDocument pfsenseDoc = XmlDocument.parse(mergeFileContents);
    //  pfsenseDoc.findAllElements('staticmap').toList().join("");
    String preLeaseXml = mergeFileContents.split("<staticmap>").first.trim();
    String postLeaseXml = mergeFileContents.split("</staticmap>").last.trim();
    List<String> staticMapTags = mergeFileContents
        .replaceFirst(preLeaseXml, "")
        .replaceFirst(postLeaseXml, "")
        .trim()
        .split("</staticmap>")
        .join("</staticmap>||")
        .split("||");

    preLeaseXml = updateIpRange(preLeaseXml);
    String template = "";
    //update existing leases with components from the input file
    for (int i = 0; i < leaseMap[g.lbMac]!.length; i++) {
      template = getStaticMapTemplateForMerge(staticMapTags, leaseMap, i)!;

      sb.write("\n${fillInStaticTemplate(template, leaseMap, i)}");
    }
    mergeFileContents = "$preLeaseXml${sb.toString()}$postLeaseXml";
    return mergeFileContents;
  }

  // ignore: slash_for_doc_comments
  /** If host ip or mac tag has a value that matches one that's in
  leaseMap then return the staticmap to be used as a template otherwise
  use generic template */
  String? getStaticMapTemplateForMerge(List<String> staticMapTags,
      Map<String, List<String>?> leaseMap, int indexOfList) {
    String value =
        "${leaseMap[g.lbHost]![indexOfList]}|${leaseMap[g.lbMac]![indexOfList]}"
        "|${leaseMap[g.lbIp]![indexOfList]}";

    //if host ip or mac tag has a value that matches one that's in
    //leaseMap then return that static map as a template

    RegExp regexp = RegExp(
        r'(<staticmap>.*?<(hostname|ipaddr|mac)>('
        "$value"
        r')</(hostname|ipaddr|mac))>.*?</staticmap>',
        caseSensitive: false,
        dotAll: true);

    late Iterable<RegExpMatch> match;

    for (String eachStaticMap in staticMapTags) {
      match = regexp.allMatches(eachStaticMap);
      if (match.isNotEmpty) break;
    }
    if (match.length == 1) {
      return match.elementAt(0).group(0);
    } else if (match.isEmpty) {
      return staticMapTemplate;
    } else {
      printMsg(
          "\u001b[33mWarning: Merge file contains two or more leases that share a common ip, hostname, and/or mac address. Using first instance and discarding others.\u001b[0m");
    }
    return staticMapTemplate;
  }
}
