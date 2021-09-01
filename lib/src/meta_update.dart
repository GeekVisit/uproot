import 'dart:io';

import 'package:yaml/yaml.dart';

class MetaUpdate {
  String pathToYaml = "pubspec.yaml";
  String metaDartFileContents = "";

  void writeMetaDartFile() {
    File metaDartFile = File("lib/src/meta.dart");

    String metaDartFileContents = """
    /// DO NOT EDIT EXCEPT INITIAL VERSION TO ADDRESS PROBLEMS  
    /// THIS FILE IS AUTOMATICALLY OVER WRITTEN BY MetaUpdate CLASS 
    /// Be Sure to Run MetaUpdate.writeMetaDartFile before compile 
     
   
   class Meta {
     // ignore: lines_longer_than_80_chars
      String description = "${getPubSpec('description')}";
      String name = "${getPubSpec('name')}";
      String version = "${getPubSpec('version')}";
   }

  """;

    metaDartFile.writeAsStringSync(metaDartFileContents);
  }

  String getPubSpec(String pubSpecParam) {
    File f = File(pathToYaml);
    String yamlText = f.readAsStringSync();
    // ignore: always_specify_types
    Map yaml = loadYaml(yamlText);
    return yaml[pubSpecParam];
  }
}
