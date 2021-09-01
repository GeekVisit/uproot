import 'dart:io';

import 'file_ops.dart';

void displayFatalException(Exception e) {
  printMsg("Error:$e. ", errMsg: true);
  exit(1);
}

void displayFatalError(Error e) {
  printMsg("Error:${e.stackTrace} ", errMsg: true);
  printMsg("${e.stackTrace}", onlyIfVerbose: true);
  exit(1);
}

void displayFatalFileSystemError(FileSystemException e) {
  printMsg("${e.message} ${e.path}", errMsg: true);
  printMsg("${e.osError?.message}", errMsg: true);
  exit(1);
}
