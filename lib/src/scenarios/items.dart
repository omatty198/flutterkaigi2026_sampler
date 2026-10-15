import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'demo_support.dart';

// ① 非同期処理中に画面を閉じた場合の比較。
final unsafeItemsProvider = NotifierProvider.autoDispose<Items, List<String>>(
  () => Items(guard: false),
);
final safeItemsProvider = NotifierProvider.autoDispose<Items, List<String>>(
  () => Items(guard: true),
);

class Items extends Notifier<List<String>> {
  Items({required this.guard});
  final bool guard;
  @override
  List<String> build() {
    final log = ref.read(logProvider);
    ref.onDispose(() => log.add('商品一覧 Provider を破棄'));
    return [];
  }

  Future<void> reload() async {
    final log = ref.read(logProvider);
    final wait = ref.read(delayProvider);
    log.add('商品一覧の読み込み開始');
    await wait();
    if (guard && !ref.mounted) {
      log.add('修正後: 表示更新を省略');
      return;
    }
    // 修正前では、画面離脱後のこの代入で例外になる。
    state = ['商品 A', '商品 B'];
    log.add('商品一覧の表示更新が完了');
  }
}
