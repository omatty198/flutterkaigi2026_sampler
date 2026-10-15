import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DemoLog extends ValueNotifier<List<String>> {
  DemoLog() : super([]);
  void add(String message) => value = [...value, message];
  void clear() => value = [];
}

final logProvider = Provider((ref) => DemoLog());
final delayProvider = Provider<Future<void> Function()>(
  (ref) =>
      () => Future<void>.delayed(const Duration(seconds: 2)),
);
