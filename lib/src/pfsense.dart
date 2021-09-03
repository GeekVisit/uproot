import 'dart:io';
import 'package:xml/xml.dart';
import 'src.dart';

class PfSense extends FileType {
  //
  //this is the appearance of the properties in the file (Mac comes first, etc.)
  static const int macIdx = 0, hostIdx = 1, ipIdx = 2;

  String fileType = fFormats.pfsense.formatName;

  @override
  //Given a string this returns Maps of the a list of each lease
  Map<String, List<String>> getLease(
      {String fileContents = "",
      List<String>? fileLines,
      bool removeBadLeases = true}) {
    //

    try {
      if (fileContents == "") {
        throw Exception(
            "Missing Argument for getLease, input file may be corrupt");
      }

      final XmlDocument pfsenseDoc = XmlDocument.parse(fileContents);

      Map<String, List<String>> leaseMap = <String, List<String>>{
        lbMac: <String>[],
        lbHost: <String>[],
        lbIp: <String>[],
      };

      leaseMap[lbMac] = pfsenseDoc
          .findAllElements('mac')
          .map((dynamic e) => e.innerText.toString())
          .toList();
      leaseMap[lbHost] = pfsenseDoc
          .findAllElements('hostname')
          .map((dynamic e) => e.innerText.toString())
          .toList();
      leaseMap[lbIp] = pfsenseDoc
          .findAllElements('ipaddr')
          .map((dynamic e) => e.innerText.toString())
          .toList();

      if (removeBadLeases) {
        return validateLeases.getValidLeaseMap(
            leaseMap, fFormats.pfsense.formatName);
      } else {
        return leaseMap;
      }
    } on Exception catch (e) {
      printMsg(e, errMsg: true);

      rethrow;
    }
  }

  String build(Map<String, List<String>?> deviceList, StringBuffer sbPfsense) {
    try {
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

      preLeaseXml = preLeaseXml.replaceAll(
          "<from></from>", "<from>${argResults['ip-low-address']}</from>");
      preLeaseXml = preLeaseXml.replaceAll(
          "<to></to>", "<to>${argResults['ip-high-address']}</to>");

      String leaseTags = leaseXml;
      String tmpLeaseTags;

      for (int x = 0; x < deviceList[lbHost]!.length; x++) {
        tmpLeaseTags = leaseTags;

        tmpLeaseTags = tmpLeaseTags.replaceAll(
            "<mac></mac>", "<mac>${deviceList[lbMac]![x]}</mac>");
        tmpLeaseTags = tmpLeaseTags.replaceAll("<hostname></hostname>",
            "<hostname>${deviceList[lbHost]![x]}</hostname>");
        tmpLeaseTags = tmpLeaseTags.replaceAll(
            "<ipaddr></ipaddr>", "<ipaddr>${deviceList[lbIp]![x]}</ipaddr>");

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

      for (int x = 0; x < deviceList[lbHost]!.length; x++) {
        tmpLeaseTags = leaseTags;

        XmlElement? tmpLeaseTag = tmpLeaseTags.firstElementChild;
        tmpLeaseTag!.getElement("mac")!.innerText = deviceList[lbMac]![x];
        tmpLeaseTag.getElement("hostname")!.innerText = deviceList[lbHost]![x];
        tmpLeaseTag.getElement("ipaddr")!.innerText = deviceList[lbIp]![x];

        sbPfsense.write("\n$tmpLeaseTag");
      }

*/

  @override
  bool isContentValid({String fileContents = "", List<String>? fileLines}) {
    try {
      ValidateLeases.initialize();
      if (fileContents == "") {
        throw Exception("Missing Argument for getLease");
      }

      dynamic leaseMap =
          getLease(fileContents: fileContents, removeBadLeases: false);

      if (validateLeases.containsBadLeases(leaseMap)) {
        return false;
      }
      validateLeases.validateLeaseList(leaseMap, fFormats.pfsense.formatName);

      return true;
    } on Exception catch (e) {
      printMsg(e, errMsg: true);
      return false;
    }
  }

  @override
  //Converts Pfsense to Json, returns json string
  String toJson() {
    StringBuffer sbJson = StringBuffer();
    String inFileContents = File(argResults['input-file']).readAsStringSync();

    //get leases from pfsense file
    Map<String, List<String>> lease = getLease(fileContents: inFileContents);

    //convert leases to json format
    for (int x = 0; x < lease[lbHost]!.length; x++) {
      if (sbJson.isNotEmpty) sbJson.write(',');

      sbJson.write('{ "$lbMac" : "${lease[lbMac]![x]}",'
          ' "$lbHost" : "${lease[lbHost]![x]}", "$lbIp" : '
          '"${lease[lbIp]![x]}" }');
    }
    return "[ ${sbJson.toString()} ]";
  }
}
