import 'dart:io';

import 'file_ops.dart';

void handleExceptions(dynamic e) {
  try {
    throw (e);
  } on FileSystemException catch (e) {
    displayFatalFileSystemException(e);
  } on FormatException catch (e) {
    printMsg(e.message, errMsg: true);
  } on Exception catch (e) {
    displayFatalException(e);
    // ignore: avoid_catching_errors
  }
}

void displayFatalException(Exception e) {
  printMsg("Error:$e. ", errMsg: true);
  exit(1);
}

void displayFatalFileSystemException(FileSystemException e) {
  printMsg("${e.message} ${e.path}", errMsg: true);
  printMsg("${e.osError?.message}", errMsg: true);
  exit(1);
}

void displayFatalError(Error e) {
  printMsg("Error:${e.stackTrace} ", errMsg: true);
  printMsg("${e.stackTrace}", onlyIfVerbose: true);
  exit(1);
}
