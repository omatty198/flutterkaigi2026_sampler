import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'demo_support.dart';

// ② read で取得した関数が Provider より長生きする場合の比較。
final messageProvider = Provider((ref) => '詳細を表示しました');
final unsafeActionProvider = Provider.autoDispose<void Function()>((ref) {
  final log = ref.read(logProvider);
  ref.onDispose(() => log.add('コールバックの Provider を破棄'));
  return () => log.add(ref.read(messageProvider));
});
final safeActionProvider = Provider<void Function()>((ref) {
  final log = ref.read(logProvider);
  ref.onDispose(() => log.add('keepAlive 相当の Provider を破棄'));
  return () => log.add(ref.read(messageProvider));
});
