import 'package:xml/xml.dart';

import 'globals.dart' as g;
import 'src.dart';

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

    try {
      if (fileContents == "") {
        throw Exception("Missing Argument for getLeaseMap in OpnSense");
      }

      final XmlDocument opnsenseDoc = XmlDocument.parse(fileContents);

      Map<String, List<String>> leaseMap = <String, List<String>>{
        g.lbMac: <String>[],
        g.lbHost: <String>[],
        g.lbIp: <String>[],
      };

      leaseMap[g.lbMac] = opnsenseDoc
          .findAllElements('mac')
          .map((dynamic e) => e.innerText.toString())
          .toList();

      leaseMap[g.lbHost] = opnsenseDoc
          .findAllElements('hostname')
          .map((dynamic e) => e.innerText.toString())
          .toList();
      leaseMap[g.lbIp] = opnsenseDoc
          .findAllElements('ipaddr')
          .map((dynamic e) => e.innerText.toString())
          .toList();

      if (removeBadLeases) {
        return g.validateLeases
            .removeBadLeases(leaseMap, g.fFormats.opnsense.formatName);
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
