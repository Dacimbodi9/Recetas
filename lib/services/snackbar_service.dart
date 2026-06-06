import 'package:flutter/material.dart';

class SnackbarService {
  static final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

  static void showMessage(String message, {Duration duration = const Duration(seconds: 3)}) {
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
      ),
    );
  }

  static void showError(String message, {Duration duration = const Duration(seconds: 4)}) {
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
