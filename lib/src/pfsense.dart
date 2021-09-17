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
        throw Exception(
            "Missing Argument for getLeaseMap in pfSense");
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

  String build(Map<String, List<String>?> deviceList) {
    try {
      StringBuffer sbPfsense = StringBuffer();
      String preLeaseXml = '''<dhcpd>
	<lan>
		<range>
			<from></from>
			<to></to>
		</range>''';

      String leaseXml = '''
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

      if (g.argResults['ip-low-address'] != null &&
          g.argResults['ip-high-address'] != null) {
        preLeaseXml = preLeaseXml.replaceAll(
            "<from></from>", "<from>${g.argResults['ip-low-address']}</from>");
        preLeaseXml = preLeaseXml.replaceAll(
            "<to></to>", "<to>${g.argResults['ip-high-address']}</to>");
      }
      String leaseTags = leaseXml;
      String tmpLeaseTags;

      for (int x = 0; x < deviceList[g.lbMac]!.length; x++) {
        tmpLeaseTags = leaseTags;

        tmpLeaseTags = tmpLeaseTags.replaceAll(
            "<mac></mac>", "<mac>${deviceList[g.lbMac]![x]}</mac>");
        tmpLeaseTags = tmpLeaseTags.replaceAll("<hostname></hostname>",
            "<hostname>${deviceList[g.lbHost]![x]}</hostname>");
        tmpLeaseTags = tmpLeaseTags.replaceAll(
            "<ipaddr></ipaddr>", "<ipaddr>${deviceList[g.lbIp]![x]}</ipaddr>");

        sbPfsense.write("\n$tmpLeaseTags");
      }
      tmpLeaseTags = sbPfsense.toString();
      sbPfsense.clear();
      return "$preLeaseXml$tmpLeaseTags\n$postLeaseXml";
    } on Exception {
      rethrow;
    }
  }

  /// ************************************* */
/* XML WAY but  slower and overkill 
/******************************************* */
      XmlDocument leaseTags = XmlDocument.parse(leaseXml);
      // ignore: unused_local_variable
      XmlDocument tmpLeaseTags = leaseTags;

      for (int x = 0; x < deviceList[g.lbMac]!.length; x++) {
        tmpLeaseTags = leaseTags;

        XmlElement? tmpLeaseTag = tmpLeaseTags.firstElementChild;
        tmpLeaseTag!.getElement("mac")!.innerText = deviceList[g.lbMac]![x];
        tmpLeaseTag.getElement("hostname")!.innerText = 
        deviceList[g.lbHost]![x];
        tmpLeaseTag.getElement("ipaddr")!.innerText = deviceList[g.lbIp]![x];

        sbPfsense.write("\n$tmpLeaseTag");
      }

*/

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
}
