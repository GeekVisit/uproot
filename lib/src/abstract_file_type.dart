// Copyright 2021 GeekVisit All rights reserved.
// Use of this source code is governed by the license in the LICENSE file.

// ignore: unused_import
import 'dart:io';

import '../lib.dart';
import 'globals.dart' as g;

abstract class FileType {
  //Returns a Map of static Leases in form of

  abstract String fileType;

  String genericXmlStaticMapTemplate = "";

  /// Gets Map of Static Leases from file contents
  ///   Removes Bad Leases by Default
  Map<String, List<String>> getLeaseMap(
      {String fileContents = "",
      List<String> fileLines,
      bool removeBadLeases = true});

  //Builds file from List of leases containing mac-address,host-name, ip address
  String build(Map<String, List<String>?> deviceList);

//Verify whether string is a valid format
  bool isContentValid({String fileContents = "", List<String> fileLines});

//Verify whether file is a valid configuration file for format
  bool isFileValid(String filePath) {
    try {
      return (isContentValid(fileContents: File(filePath).readAsStringSync()));
    } on Exception catch (e) {
      if (g.testRun) {
        rethrow;
      } else {
        printMsg(e, errMsg: true);
        return false;
      }
    }
  }

  ///  Used for Pfs and Opn conversions.
  /// Updates XMl tag to reflect hi-low
  String updateXmlIpRange(String preLeaseXml) {
    if (g.argResults['ip-low-address'] != null &&
        g.argResults['ip-high-address'] != null) {
      preLeaseXml = preLeaseXml.replaceAll(
          "<from></from>", "<from>${g.argResults['ip-low-address']}</from>");
      preLeaseXml = preLeaseXml.replaceAll(
          "<to></to>", "<to>${g.argResults['ip-high-address']}</to>");
    }
    return preLeaseXml;
  }

  ///  Fills in in the staticmap templates with lease components.
  ///  Use for Pfs and Opn conversions

  String fillInXmlStaticTemplate(
      String tmpLeaseTags, Map<String, List<String>?> leaseMap, int x) {
    tmpLeaseTags = tmpLeaseTags.replaceAll(
        "<mac></mac>", "<mac>${leaseMap[g.lbMac]![x]}</mac>");
    tmpLeaseTags = tmpLeaseTags.replaceAll("<hostname></hostname>",
        "<hostname>${leaseMap[g.lbHost]![x]}</hostname>");
    tmpLeaseTags = tmpLeaseTags.replaceAll(
        "<ipaddr></ipaddr>", "<ipaddr>${leaseMap[g.lbIp]![x]}</ipaddr>");
    return tmpLeaseTags;
  }

  ///   Used for Pfs and Opn conversions. Keeps and updates existing
  ///   lease in merge file and adds new ones from input.
  ///
  String mergeXmlTags(Map<String, List<String>?> leaseMap) {
    StringBuffer sb = StringBuffer();

    String mergeFileContents = File(g.argResults['merge']).readAsStringSync();

    String preLeaseXml = mergeFileContents.split("<staticmap>").first.trim();
    String postLeaseXml = mergeFileContents.split("</staticmap>").last.trim();
    List<String> staticMapTags = mergeFileContents
        .replaceFirst(preLeaseXml, "")
        .replaceFirst(postLeaseXml, "")
        .trim()
        .split("</staticmap>")
        .join("</staticmap>||")
        .split("||");

    preLeaseXml = updateXmlIpRange(preLeaseXml);
    String template = "";
    //update existing leases with components from the input file

    for (int i = 0; i < leaseMap[g.lbMac]!.length; i++) {
      template = getXmlStaticMapTemplateForMerge(
        staticMapTags,
        leaseMap,
        i,
      )!;

      sb.write("\n${fillInXmlStaticTemplate(template, leaseMap, i)}");
    }
    mergeFileContents = "$preLeaseXml${sb.toString()}$postLeaseXml";
    return mergeFileContents;
  }

  ///  Used for Opn and Pfs conversions. If host ip or mac tag has a value that
  ///  matches one that's in leaseMap then return the staticmap to be used as a
  ///  template otherwise  use generic template
  String? getXmlStaticMapTemplateForMerge(List<String> staticMapTags,
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
      return genericXmlStaticMapTemplate;
    } else {
      printMsg("""
${g.colorWarning}Warning: Merge file contains two or more leases that share"""
          "a common ip, hostname, and/or mac address. Using first instance and"
          " discarding others.${g.ansiFormatEnd}");
    }
    return genericXmlStaticMapTemplate;
  }
}
