import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterkaigi2026_sampler/main.dart';
import 'package:flutterkaigi2026_sampler/scenarios.dart';

void main() {
  testWidgets('比較する3ケースとログが表示される', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SampleApp()));
    expect(find.text('① await 中の画面離脱'), findsOneWidget);
    expect(find.text('② Provider より長生きする関数'), findsOneWidget);
    expect(find.text('③ 保存と共有キャッシュ'), findsOneWidget);
    expect(find.text('実行ログ'), findsOneWidget);
  });

  for (final safe in [false, true]) {
    testWidgets('商品一覧の画面離脱を操作して比較 safe=$safe', (tester) async {
      final completion = Completer<void>();
      final log = DemoLog();
      addTearDown(log.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            logProvider.overrideWithValue(log),
            delayProvider.overrideWithValue(() => completion.future),
          ],
          child: const SampleApp(),
        ),
      );
      final open = find.text(safe ? '修正後を開く' : '修正前を開く').first;
      await tester.ensureVisible(open);
      await tester.tap(open);
      await tester.pumpAndSettle();
      await tester.tap(find.text('読み込みを開始（2秒）'));
      await tester.pump();
      await tester.tap(find.text('画面を閉じる'));
      await tester.pumpAndSettle();
      expect(log.value, contains('商品一覧 Provider を破棄'));
      completion.complete();
      await tester.pumpAndSettle();
      if (safe) {
        expect(log.value, contains('修正後: 表示更新を省略'));
      } else {
        expect(log.value.any((entry) => entry.startsWith('例外:')), isTrue);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
