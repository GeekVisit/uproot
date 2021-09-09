import 'dart:io';

import 'dart:math';
import 'package:path/path.dart' as p;
import 'globals.dart' as g;

void printMsg(dynamic message,
    {bool errMsg = false, bool onlyIfVerbose = false, bool logOnly = false}) {
  if (errMsg) {
    stderr.writeln(message.toString().replaceFirst("Exception:", "").trim());
  } else if (!logOnly) {
    if (onlyIfVerbose) {
      (g.argResults['verbose']) ? stdout.writeln(message) : "";
    } else {
      stdout.writeln(message.toString().replaceFirst("Exception:", "").trim());
    }

    //Write to Log
    try {
      if (g.logPath != "") {
        File logFile = File(g.logPath);
        logFile.writeAsStringSync(
            // ignore: lines_longer_than_80_chars
            "${"$message  ${g.newL} ${StackTrace.current}".toString().trim()}${g.newL}",
            mode: FileMode.append);
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

///  Returns temporary filepath for temporary uprt conversion file

File getTmpIntermedConvFile(String baseName, {String extension = ".tmp"}) {
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
