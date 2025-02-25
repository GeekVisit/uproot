// Copyright 2025 GeekVisit All rights reserved.
// Use of this source code is governed by the license in the LICENSE file.

/// Handles various types of exceptions and performs appropriate actions based on the exception type.
///

import 'dart:io';

import '../lib.dart';

import 'file_ops.dart';

/// This function attempts to throw and catch the provided exception `e` and handles it accordingly:
/// - If the exception is a `FileSystemException`, it calls `displayFatalFileSystemException(e)`.
/// - If the exception is a `FormatException`, it prints the exception message using `printMsg(e.message.toString(), errMsg: true)`.
/// - For any other `Exception`, it calls `displayFatalException(e)`.
///
/// If an exception is caught in the outer try-catch block, it prints the exception using `printMsg(e, onlyIfVerbose: true, logOnly: true)`
/// and then rethrows the exception.
///
/// Note: The inner try-catch block ignores errors that are not of type `Exception`.
///
/// Parameters:
/// - `e`: The exception to be handled.
///

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
