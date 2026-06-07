import 'dart:async';
import 'dart:collection';

class SerialEventQueue {
  final Queue<_QueuedEvent<dynamic>> _events = Queue();
  bool _isProcessing = false;

  Future<T> add<T>(FutureOr<T> Function() event) {
    final completer = Completer<T>();
    _events.add(_QueuedEvent<T>(event, completer));
    _process();
    return completer.future;
  }

  Future<void> _process() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      while (_events.isNotEmpty) {
        final event = _events.removeFirst();
        await event.run();
      }
    } finally {
      _isProcessing = false;
    }
  }
}

class _QueuedEvent<T> {
  final FutureOr<T> Function() event;
  final Completer<T> completer;

  _QueuedEvent(this.event, this.completer);

  Future<void> run() async {
    try {
      completer.complete(await event());
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
    }
  }
}
