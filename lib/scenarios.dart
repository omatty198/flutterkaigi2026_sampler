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

// 画面の Provider とは独立し、アプリ内で共有するサービス。
class ProfileService {
  ProfileService(this.log, this.wait);
  final DemoLog log;
  final Future<void> Function() wait;
  int cacheUpdates = 0;

  Future<void> save() async {
    log.add('サーバーへの保存開始');
    await wait();
    log.add('サーバーへの保存完了（模擬）');
  }

  Future<void> refreshCache() async {
    cacheUpdates++;
    log.add('共有キャッシュを更新');
  }

  Future<void> saveAndRefreshCache() async {
    await save();
    await refreshCache();
  }
}

final profileServiceProvider = Provider(
  (ref) => ProfileService(ref.read(logProvider), ref.read(delayProvider)),
);
final unsafeProfileProvider = NotifierProvider.autoDispose<Profile, String>(
  () => Profile(safe: false),
);
final safeProfileProvider = NotifierProvider.autoDispose<Profile, String>(
  () => Profile(safe: true),
);

class Profile extends Notifier<String> {
  Profile({required this.safe});
  final bool safe;
  @override
  String build() {
    final log = ref.read(logProvider);
    ref.onDispose(() => log.add('プロフィール画面の Provider を破棄'));
    return '未保存';
  }

  Future<void> save() async {
    final service = ref.read(profileServiceProvider);
    final log = ref.read(logProvider);
    if (safe) {
      await service.saveAndRefreshCache();
    } else {
      await service.save();
      if (!ref.mounted) {
        log.add('修正前: return でキャッシュ更新も省略された');
        return;
      }
      await service.refreshCache();
    }
    if (!ref.mounted) {
      log.add('画面用の表示更新だけ省略');
      return;
    }
    state = '保存しました';
    log.add('保存完了を画面に表示');
  }
}
