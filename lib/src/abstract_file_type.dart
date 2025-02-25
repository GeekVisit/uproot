// Copyright 2025 GeekVisit All rights reserved.
// Use of this source code is governed by the license in the LICENSE file.

// ignore: unused_import
import 'dart:io';

import '../lib.dart';
import 'globals.dart' as g;

/// An abstract class representing a file type with methods to handle static leases.
///
/// This class provides methods to get a map of static leases from file contents,
/// build a file from a list of leases, verify the validity of file contents and
/// configuration files, update XML tags, fill in XML static templates, and merge
/// XML tags.
///
/// Properties:
/// - `fileType`: The type of the file.
/// - `genericXmlStaticMapTemplate`: A template for the generic XML static map.
///
/// Methods:
/// - `getLeaseMap`: Gets a map of static leases from file contents. Removes bad leases by default.
/// - `build`: Builds a file from a list of leases containing mac-address, host-name, and IP address.
/// - `isContentValid`: Verifies whether the string is in a valid format.
/// - `isFileValid`: Verifies whether the file is a valid configuration file for the format.
/// - `updateXmlIpRange`: Updates XML tags to reflect high-low IP ranges.
/// - `fillInXmlStaticTemplate`: Fills in the static map templates with lease components.
/// - `mergeXmlTags`: Keeps and updates existing leases in the merge file and adds new ones from input.
/// - `getXmlStaticMapTemplateForMerge`: Returns the static map to be used as a template if host, IP, or MAC tag matches one in the lease map, otherwise uses a generic template.
abstract class FileType {
  //Returns a Map of static Leases in form of
//these get overridden by individual classes
  abstract String fileType;

  String genericXmlStaticMapTemplate = "";

  /// Gets Map of Static Leases from file contents
  ///   Removes Bad Leases by Default
  Map<String, List<String>> getLeaseMap(
      {String fileContents = "",
      List<String> fileLines,
      bool removeBadLeases = true});

  //Builds file from List of leases containing mac-address,host-name, ip address
  String buildOutFileContents(Map<String, List<String>?> leaseMap);

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
    tmpLeaseTags = tmpLeaseTags.replaceAll("<mac></mac>",
        "<mac>${this.reformatMacForType(leaseMap[g.lbMac]![x], fileType)}</mac>");
    tmpLeaseTags = tmpLeaseTags.replaceAll("<hostname></hostname>",
        "<hostname>${leaseMap[g.lbHost]![x]}</hostname>");
    tmpLeaseTags = tmpLeaseTags.replaceAll(
        "<ipaddr></ipaddr>", "<ipaddr>${leaseMap[g.lbIp]![x]}</ipaddr>");
    return tmpLeaseTags;
  }

  /// Reformats a MAC address based on the specified file type and delimiter.
  ///
  /// This function takes a MAC address and a file type, then reformats the MAC
  /// address according to the delimiter specified for that file type. If a custom
  /// delimiter is provided via command-line arguments, it will be used instead of
  /// the default delimiter for the file type.
  ///
  /// If the delimiter for the file type is "|", and no custom delimiter is provided,
  /// the MAC address will be returned as is.
  ///
  /// The function replaces the current delimiter in the MAC address with the new
  /// delimiter. The current delimiter is assumed to be either ":" or "-", and the
  /// new delimiter is determined based on the file type or command-line argument.
  ///
  /// Parameters:
  /// - `mac` (String): The MAC address to be reformatted.
  /// - `fileType` (String): The type of file for which the MAC address is being reformatted.
  ///
  /// Returns:
  /// - `String`: The reformatted MAC address.

  reformatMacForType(String mac, String fileType) {
    String replaceDelim =
        g.argResults['mac-delimiter'] ?? g.macDelimiter[fileType]!;

    String searchDelim = replaceDelim == ":" ? "-" : ":";

    return g.macDelimiter[fileType] == "|" &&
            g.argResults['mac-delimiter'] == null
        ? mac
        : mac.replaceAll(searchDelim, replaceDelim.trim());
  }

  ///   Used for Pfs and Opn conversions. Keeps and updates existing
  ///   lease in merge file and adds new ones from input.
  ///
  /// Merges XML tags from a given lease map into an existing XML file.
  ///
  /// This function reads an XML file specified by the 'merge' argument,
  /// updates the XML content with the provided lease map, and returns
  /// the merged XML content as a string.
  ///
  /// The function performs the following steps:
  /// 1. Reads the content of the XML file specified by the 'merge' argument.
  /// 2. Splits the XML content into three parts: pre-lease XML, static map tags, and post-lease XML.
  /// 3. Updates the IP range in the pre-lease XML.
  /// 4. Iterates over the lease map and updates existing leases with components from the input file.
  /// 5. Merges the updated leases into the XML content and returns the final merged XML content.
  ///
  /// Parameters:
  /// - `leaseMap`: A map where the key is a string and the value is a list of strings representing the lease information.
  ///
  /// Returns:
  /// - A string containing the merged XML content.
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

  ///
  /// This method searches through the provided `staticMapTags` to find a match
  /// for the host IP or MAC address in the `leaseMap`. If a match is found, it
  /// returns the corresponding static map template. If no match is found, it
  /// returns a generic static map template. If multiple matches are found, it
  /// logs a warning and returns the first match.
  ///
  /// - Parameters:
  ///   - staticMapTags: A list of static map tags to search through.
  ///   - leaseMap: A map containing lease information with keys for host, IP, and MAC.
  ///   - indexOfList: The index to access the lease information in the `leaseMap`.
  ///
  /// - Returns: A string containing the XML static map template.
  /// If a match is found, it returns the corresponding static map template.
  /// If no match is found, it returns a generic static map template.

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
