import 'package:flutter/services.dart';

Future<T?> invokeMethodWithRetry<T>(
  MethodChannel channel,
  String method, [
  dynamic arguments,
  int maxAttempts = 5,
  Duration delay = const Duration(milliseconds: 150),
]) async {
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      return await channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      if (attempt == maxAttempts - 1) rethrow;
      await Future.delayed(delay);
    }
  }
  return null;
}
