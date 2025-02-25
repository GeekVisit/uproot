// Copyright 2025 GeekVisit All rights reserved.
// Use of this source code is governed by the license in the LICENSE file.

import 'dart:io';
import 'dart:math';

import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as p;
import 'package:validators/sanitizers.dart';

import 'globals.dart' as g;

/// Prints a message to the console or logs it to a file.
///
/// The message can be printed as an error message, only if verbose mode is enabled,
/// or only logged to a file based on the provided parameters.
///
/// - [msgToPrint]: The message to be printed or logged. Can be of any type.
/// - [errMsg]: If `true`, the message is printed as an error message to `stderr`.
/// - [onlyIfVerbose]: If `true`, the message is printed only if verbose mode is enabled.
/// - [logOnly]: If `true`, the message is only logged to a file and not printed to the console.
///
/// The function also handles printing stack traces if verbose-debug mode is enabled,
/// and logs messages to a file if logging is enabled.
///
/// Throws:
/// - [FormatException]: If there is an error formatting the log message.
/// - [Exception]: For any other exceptions that occur during logging.
void printMsg(
  dynamic msgToPrint, {
  bool errMsg = false,
  bool onlyIfVerbose = false,
  bool logOnly = false,
}) {
  try {
    String msg = msgToPrint.toString();
    g.lastPrint = msg.toString().replaceFirst("Exception:", "").trim();

    if (errMsg) {
      stderr.writeln(
          """${g.colorError}${msg.toString().replaceFirst("Exception: ", "").trim()} ${g.ansiFormatEnd} """);
    } else if (!logOnly) {
      if (onlyIfVerbose) {
        (g.verbose) ? stdout.writeln(msg) : "";
      } else {
        stdout.writeln(msg.toString().replaceFirst("Exception:", "").trim());
      }
    }

    /* Print Stack Trace if Debug */
    if (g.argResults['verbose-debug'] != null &&
        g.argResults['verbose-debug']) {
      stdout.writeln(
          "${g.newL} ${StackTrace.current.toString().trim()} ${g.newL}");
    }

    //Write to Log
    try {
      if (g.argResults['log'] != null && g.argResults['log']) {
        //strip color codes
        msg = stripLow(msg)
            .replaceAll(RegExp('[[0-9]+m', multiLine: false, dotAll: true), "");
        File logFile = File(g.logPath);
        logFile.writeAsStringSync("${stripLow(msg)} ${g.newL}",
            mode: FileMode.append);
        /* Log Stack Trace if Debug */
        if (g.argResults['verbose-debug'] != null &&
            g.argResults['verbose-debug']) {
          logFile.writeAsStringSync(
              // ignore: prefer_interpolation_to_compose_strings
              """
    ${g.newL}${StackTrace.current.toString().trim()}${g.newL})"""
              "${g.newL}", mode: FileMode.append);
        }
      }
    } on FormatException catch (e) {
      print("${e.message.toString()} (log file)");
      return;
    } on Exception {
      stdout.writeln(msg.toString().replaceFirst("Exception:", "").trim());
      return;
    }
  } on Exception {
    rethrow;
  }
}

/// Saves the given contents to a file at the specified path.
///
/// If [overWrite] is set to `false` (default), the method will create a new file
/// with a unique name if a file with the same name already exists. The new file
/// name will have a numeric suffix (e.g., `filename(01).ext`, `filename(02).ext`).
///
/// If [overWrite] is set to `true`, the method will overwrite any existing file
/// with the same name.
///
/// Throws an [Exception] if an error occurs during file operations.
///
/// - Parameters:
///   - contents: The content to be saved to the file.
///   - savePath: The path where the file should be saved.
///   - overWrite: A boolean flag indicating whether to overwrite an existing file.
///
/// - Returns: The absolute path of the saved file.
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

/// Deletes files, excepts shell expansion globs
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

/// Get contents of file
String getFileContents(String filePath) {
  return File(filePath).readAsStringSync();
}

