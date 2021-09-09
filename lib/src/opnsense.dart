import 'dart:io';

import 'package:xml/xml.dart';

import 'globals.dart' as g;
import 'src.dart';

class OpnSense extends FileType {
  //
  //this is the appearance of the properties in the file (Mac comes first, etc.)
  static const int macIdx = 0, hostIdx = 1, ipIdx = 2;

  String fileType = g.fFormats.opnsense.formatName;

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
            .getValidLeaseMap(leaseMap, g.fFormats.opnsense.formatName);
      } else {
        return leaseMap;
      }
    } on Exception catch (e) {
      printMsg(e, errMsg: true);

      rethrow;
    }
  }

  String build(Map<String, List<String>?> deviceList, StringBuffer sbOpnsense) {
    try {
      String preLeaseXml = '''<?xml version="1.0"?>
<opnsense>
<dhcpd>
    <lan>''';

      String leaseXml = '''
 		      <staticmap>
        <mac></mac>
        <ipaddr></ipaddr>
        <hostname></hostname>        
      </staticmap>''';

      String postLeaseXml = '''
     </lan>  
  </dhcpd>
  </opnsense>''';

      String leaseTags = leaseXml;
      String tmpLeaseTags;

      for (int x = 0; x < deviceList[g.lbHost]!.length; x++) {
        tmpLeaseTags = leaseTags;

        tmpLeaseTags = tmpLeaseTags.replaceAll(
            "<mac></mac>", "<mac>${deviceList[g.lbMac]![x]}</mac>");
        tmpLeaseTags = tmpLeaseTags.replaceAll("<hostname></hostname>",
            "<hostname>${deviceList[g.lbHost]![x]}</hostname>");
        tmpLeaseTags = tmpLeaseTags.replaceAll(
            "<ipaddr></ipaddr>", "<ipaddr>${deviceList[g.lbIp]![x]}</ipaddr>");

        sbOpnsense.write("\n$tmpLeaseTags");
      }
      tmpLeaseTags = sbOpnsense.toString();
      sbOpnsense.clear();
      return "$preLeaseXml$tmpLeaseTags\n$postLeaseXml";
    } on Exception {
      rethrow;
    }
  }

  @override
  bool isContentValid({String fileContents = "", List<String>? fileLines}) {
    try {
      ValidateLeases.initialize();
      if (fileContents == "") {
        throw Exception("Missing Argument for getLease");
      }

      dynamic leaseMap =
          getLease(fileContents: fileContents, removeBadLeases: false);

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

  @override
  //Converts Opnsense to Json, returns json string
  String toJson() {
    StringBuffer sbJson = StringBuffer();
    String inFileContents = File(g.inputFile).readAsStringSync();

    //get leases from opnsense file
    Map<String, List<String>> lease = getLease(fileContents: inFileContents);

    //convert leases to json format
    for (int x = 0; x < lease[g.lbHost]!.length; x++) {
      if (sbJson.isNotEmpty) sbJson.write(',');

      sbJson.write('{ "g.lbMac" : "${lease[g.lbMac]![x]}",'
          ' "g.lbHost" : "${lease[g.lbHost]![x]}", "g.lbIp" : '
          '"${lease[g.lbIp]![x]}" }');
    }
    return "[ ${sbJson.toString()} ]";
  }
}
