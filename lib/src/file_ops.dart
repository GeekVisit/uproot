import 'dart:io';

import 'dart:math';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as p;
import 'globals.dart' as g;

void printMsg(
  dynamic msg, {
  bool errMsg = false,
  bool onlyIfVerbose = false,
  bool logOnly = false,
}) {
  if (errMsg) {
    stderr.writeln(msg.toString().replaceFirst("Exception:", "").trim());
  } else if (!logOnly) {
    if (onlyIfVerbose) {
      (g.argResults['verbose']) ? stdout.writeln(msg) : "";
    } else {
      stdout.writeln(msg.toString().replaceFirst("Exception:", "").trim());
    }
  }

/* Print Stack Trace if Debug */
  if (g.argResults['verbose-debug']) {
    stdout.writeln("${g.newL}${StackTrace.current.toString().trim()}${g.newL}");
  }

  //Write to Log
  try {
    if (g.argResults['log']) {
      File logFile = File(g.logPath);
      logFile.writeAsStringSync(
          // ignore: lines_longer_than_80_chars
          "$msg  ${g.newL}",
          mode: FileMode.append);
      /* Log Stack Trace if Debug */
      if (g.argResults['verbose-debug']) {
        logFile.writeAsStringSync(
            "${g.newL}${StackTrace.current.toString().trim()}${g.newL}");
      }
    }
  } on FormatException catch (e) {
    if (!g.testRun) {
      print("${e.message} (log file)");
    }
    rethrow;
  } on Exception {
    //print(e);
    rethrow;
  }
}

String saveFile(String contents, String savePath, {bool overWrite = false}) {
  try {
    int x = 1;
    File fileToSave = File(savePath);
    String fileToSaveBaseName = p.basenameWithoutExtension(savePath);
    String ext = p.extension(savePath);

    if (!overWrite) {
      while (fileToSave.existsSync()) {
        fileToSave = File(p.join(p.dirname(savePath),
            "$fileToSaveBaseName(${x.toString().padLeft(2, '0')})$ext"));
        x++;
      }
    }

    fileToSave.writeAsStringSync(contents.trim());

    //return name of file saved as may change if exists and didn't overwrite
    return fileToSave.absolute.path;
  } on Exception catch (e) {
    printMsg(e, errMsg: true);
    rethrow;
  }
}

/// Returns temporary filepath for temporary uprt file
/// 2021-09 Deprecated currently, may not need */

File getTmpFile(String baseName, {String extension = ".tmp"}) {
  // ignore: unused_local_variable
  int x = 1;
  File temp =
      File(p.join(g.tempDir.path, "${g.argResults['base-name']}$extension"));

  while (temp.existsSync()) {
    temp = File(p.join(g.tempDir.path,
        "uprt_$baseName\_${getRandomString(6)}$extension".replaceAll("'", "")));
    x++;
  }

  return temp;
}

String getRandomString(int length) {
  //https://stackoverflow.com/a/61929967/2205849

  const String chars = '''
AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890''';
  Random rnd = Random();

  // ignore: always_specify_types
  return String.fromCharCodes(Iterable.generate(
      length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
}

/// Returns true if string is a valid path and parent exists */
bool isStringAValidFilePath(String testPath) {
  try {
    File filePath = File(testPath);
    return filePath.parent.existsSync();
  } on Exception catch (e) {
    printMsg(e, logOnly: true);
    return false;
  }
}

// ignore: slash_for_doc_comments
/** Deletes files, excepts shell expansion globs */
void deleteFiles(String filesGlobToDelete) {
  try {
    Glob listOfFilesToDelete = Glob(filesGlobToDelete);

    for (FileSystemEntity file in listOfFilesToDelete.listSync()) {
      file.deleteSync();
    }
  } on Exception {
    rethrow;
  }
}

String getGoodPath(String fPath) {
  try {
    return p.canonicalize(File(fPath).absolute.path);
  } on Exception {
    rethrow;
  }
}

// ignore: slash_for_doc_comments
/** Get contents of json file, or temporary json file if none given */
String getFileContents(String filePath) {
  return File(filePath).readAsStringSync();
}
