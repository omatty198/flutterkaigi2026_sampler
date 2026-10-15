import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterkaigi2026_sampler/main.dart';

void main() {
  testWidgets('比較する3ケースとログが表示される', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SampleApp()));
    expect(find.text('① await 中の画面離脱'), findsOneWidget);
    expect(find.text('② Provider より長生きする関数'), findsOneWidget);
    expect(find.text('③ 保存と共有キャッシュ'), findsOneWidget);
    expect(find.text('実行ログ'), findsOneWidget);
  });
}
