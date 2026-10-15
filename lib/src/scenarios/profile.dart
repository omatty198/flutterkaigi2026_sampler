import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'demo_support.dart';

// ③ 保存後の共有キャッシュ更新を、画面の寿命から切り離す比較。
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
