import 'dart:io';

import 'package:xml/xml.dart';
import 'globals.dart' as g;
import 'src.dart';

class PfSense extends FileType {
  //
  //this is the appearance of the properties in the file (Mac comes first, etc.)
  static const int macIdx = 0, hostIdx = 1, ipIdx = 2;

  String fileType = g.fFormats.pfsense.formatName;

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

      preLeaseXml = updateIpRange(preLeaseXml);

      String tmpLeaseTags;

      if (g.argResults['merge'] != null && mergeTargetFileType == "p") {
        return mergeLeaseMapsIntoPfsMergeFile(leaseMap, staticMapTemplate);
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
      String staticMapTemplate, Map<String, List<String>?> leaseMap, int x) {
    String tmpLeaseTags = staticMapTemplate;
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
  String mergeLeaseMapsIntoPfsMergeFile(
      Map<String, List<String>?> leaseMap, String staticMapTemplate) {
    StringBuffer sb = StringBuffer();

    String mergeFileContents = File(g.argResults['merge']).readAsStringSync();
    final XmlDocument pfsenseDoc = XmlDocument.parse(mergeFileContents);
    String preLeaseXml = mergeFileContents.split("<staticmap>").first.trim();
    List<XmlElement> staticMapTags =
        pfsenseDoc.findAllElements('staticmap').toList();
    String postLeaseXml = mergeFileContents.split("</staticmap>").last.trim();
    List<int> newLeases = <int>[];
    bool leaseIsNew = true;

    preLeaseXml = updateIpRange(preLeaseXml);

    //update existing leases with components from the input file
    for (int i = 0; i < leaseMap[g.lbMac]!.length; i++) {
      leaseIsNew = true; //set newLease flag to default
      //get all static maps
      if (staticMapTags.length == 0) {
        break;
      }

      for (int x = 0; x < staticMapTags.length; x++) {
        //Update static map. If fails to update (i.e., host, ip, or mac
        //are not the same as in leaseMap, it must be a totally unique new lease
        //and will need to add a unique staticMap tag using
        //the staticMapTemplate.

        if (updateStaticMap(staticMapTags[x].outerXml, leaseMap, i, sb)) {
          staticMapTags
              .removeAt(x); //remove as have updated and added to new leases
          leaseIsNew = false;
          break;
        }
      } //end updating static maps

      if (leaseIsNew) {
        newLeases.add(i); //add to new leases to add
      }
    }
    // add any new leases using the staticMapTemplate
    for (int i in newLeases) {
      sb.write("\n${fillInStaticTemplate(staticMapTemplate, leaseMap, i)}");
    }
    mergeFileContents = "$preLeaseXml${sb.toString()}$postLeaseXml";
    return mergeFileContents;
  }

/* Replaces by regex the leases in  <staticmap> tag with the 
lease in the leaseMap when one of the components (host/ip/mac) in static map  
matches corresponding component of leaseMap.
Returns true if map is updated, false if not
*/

  bool updateStaticMap(String staticMap, Map<String, List<String>?> leaseMap,
      int indexOfList, StringBuffer sb) {
    String value =
        "${leaseMap[g.lbHost]![indexOfList]}|${leaseMap[g.lbMac]![indexOfList]}"
        "|${leaseMap[g.lbIp]![indexOfList]}";

    //if host ip or mac tag has a value that matches one that's in
    //leaseMap then replace with whats in lease tag
    String staticMapUpdated = staticMap.replaceAllMapped(
        RegExp(
            r'(<(hostname|ipaddr|mac)>(' "$value" r')</(hostname|ipaddr|mac))',
            caseSensitive: false),
        (dynamic m) => (m[2] == "hostname")
            ? "<${m[2]}>${leaseMap[g.lbHost]![indexOfList]}</${m[4]}"
            : (m[2] == "mac")
                ? "<${m[2]}>${leaseMap[g.lbMac]![indexOfList]}</${m[4]}>"
                : (m[2] == "ipaddr")
                    ? "<${m[2]}>${leaseMap[g.lbIp]![indexOfList]}</${m[4]}>"
                    : "");

    if ((staticMapUpdated != staticMap)) (sb.write(staticMapUpdated));

    return (staticMapUpdated != staticMap); //return true if theres a change
  }
}
