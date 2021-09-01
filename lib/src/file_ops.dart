import 'dart:io';

import 'dart:math';
import 'package:path/path.dart' as p;
import '../lib.dart';
import 'globals.dart';

void printMsg(dynamic message,
    {bool errMsg = false, bool onlyIfVerbose = false, bool logOnly = false}) {
  if (errMsg) {
    stderr.writeln(message.toString().replaceFirst("Exception:", "").trim());
  } else if (!logOnly) {
    if (onlyIfVerbose) {
      (argResults['verbose']) ? stdout.writeln(message) : "";
    } else {
      stdout.writeln(message.toString().replaceFirst("Exception:", "").trim());
    }

    //Write to Log
    try {
      if (logPath != "") {
        File logFile = File(logPath);
        logFile.writeAsStringSync(
            "${"$message  $newL ${StackTrace.current}".toString().trim()}$newL",
            mode: FileMode.append);
      }
    } on FormatException catch (e) {
      if (!testRun) {
        print("${e.message} (log file)");
      }
      rethrow;
    } on Exception {
      //print(e);
      rethrow;
    }
  }
}

String saveOutFile(String outContents, String outputPath,
    {bool overWrite = false}) {
  try {
    int x = 1;
    File outputFile = File(outputPath);
    String outputBaseFileName = p.basenameWithoutExtension(outputFile.path);
    String ext = p.extension(outputFile.path);

    if (!overWrite) {
      while (outputFile.existsSync()) {
        outputFile = File(p.join(p.dirname(outputPath),
            "$outputBaseFileName(${x.toString().padLeft(2, '0')})$ext"));
        x++;
      }
    }

    outputFile.writeAsStringSync(outContents.trim());

    //return name of file saved as may change if exists and didn't overwrite
    return outputFile.absolute.path;
  } on Exception catch (e) {
    printMsg(e, errMsg: true);
    rethrow;
  }
}

void saveFile(String contents, String filePath) {
  File saveFile = File(filePath);
  saveFile.writeAsStringSync;
}

///  Returns temporary filepath for temporary uprt conversion file

File getTmpIntermedConvFile(String baseName, {String extension = ".tmp"}) {
  // ignore: unused_local_variable
  int x = 1;
  File temp =
      File(p.join(tempDir.path, "${argResults['base-name']}$extension"));

  while (temp.existsSync()) {
    temp = File(p.join(tempDir.path,
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
