import 'dart:async';

class Mutex {
  Future<void>? _lock;

  Future<T> synchronized<T>(Future<T> Function() computation) async {
    while (_lock != null) {
      await _lock;
    }
    final completer = Completer<void>();
    _lock = completer.future;
    try {
      return await computation();
    } finally {
      _lock = null;
      completer.complete();
    }
  }
}

final globalWriteMutex = Mutex();
