import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterkaigi2026_sampler/scenarios.dart';

void main() {
  for (final safe in [false, true]) {
    test('商品一覧: 画面離脱 safe=$safe', () async {
      final pending = Completer<void>();
      final c = ProviderContainer(
        overrides: [delayProvider.overrideWithValue(() => pending.future)],
      );
      addTearDown(c.dispose);
      final provider = safe ? safeItemsProvider : unsafeItemsProvider;
      final sub = c.listen(provider, (_, _) {});
      final future = c.read(provider.notifier).reload();
      sub.close();
      await c.pump();
      expect(c.exists(provider), false);
      final assertion = safe
          ? expectLater(future, completes)
          : expectLater(
              future,
              throwsA(
                predicate<Object>((e) => e.toString().contains('disposed')),
              ),
            );
      pending.complete();
      await assertion;
    });
    test('プロフィール: 画面離脱 safe=$safe', () async {
      final pending = Completer<void>();
      final c = ProviderContainer(
        overrides: [delayProvider.overrideWithValue(() => pending.future)],
      );
      addTearDown(c.dispose);
      final provider = safe ? safeProfileProvider : unsafeProfileProvider;
      final sub = c.listen(provider, (_, _) {});
      final service = c.read(profileServiceProvider);
      final future = c.read(provider.notifier).save();
      sub.close();
      await c.pump();
      expect(c.exists(provider), false);
      pending.complete();
      await future;
      expect(service.cacheUpdates, safe ? 1 : 0);
    });
    test('通常完了: 商品一覧と保存 safe=$safe', () async {
      final c = ProviderContainer(
        overrides: [delayProvider.overrideWithValue(() async {})],
      );
      addTearDown(c.dispose);
      final items = safe ? safeItemsProvider : unsafeItemsProvider;
      final profile = safe ? safeProfileProvider : unsafeProfileProvider;
      final s1 = c.listen(items, (_, _) {});
      final s2 = c.listen(profile, (_, _) {});
      await c.read(items.notifier).reload();
      await c.read(profile.notifier).save();
      expect(c.read(items), ['商品 A', '商品 B']);
      expect(c.read(profile), '保存しました');
      s1.close();
      s2.close();
    });
  }
  test('関数は autoDispose 後に失敗し、自動破棄なしなら成功する', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final bad = c.read(unsafeActionProvider);
    final good = c.read(safeActionProvider);
    await c.pump();
    expect(
      bad,
      throwsA(predicate<Object>((e) => e.toString().contains('disposed'))),
    );
    good();
    expect(c.read(logProvider).value.last, '詳細を表示しました');
    c.refresh(safeActionProvider);
    expect(
      good,
      throwsA(predicate<Object>((e) => e.toString().contains('disposed'))),
    );
  });
}
