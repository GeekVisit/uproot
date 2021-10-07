// Copyright 2021 GeekVisit All rights reserved.
// Use of this source code is governed by the license in the LICENSE file.

import 'dart:io';

import '../lib.dart';

import 'file_ops.dart';

void handleExceptions(dynamic e) {
  try {
    try {
      throw (e);
    } on FileSystemException catch (e) {
      displayFatalFileSystemException(e);
    } on FormatException catch (e) {
      printMsg(e.message.toString(), errMsg: true);
    } on Exception catch (e) {
      displayFatalException(e);
      // ignore: avoid_catching_errors
    }
  } on Exception catch (e) {
    printMsg(e, onlyIfVerbose: true, logOnly: true);
    rethrow;
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
