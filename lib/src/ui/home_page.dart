import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../scenarios.dart';
import 'detail_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.read(logProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Riverpod 3 · Ref の寿命')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                '修正前と修正後を、同じ操作で比較',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text('API は 2 秒待つ模擬処理です。例外は比較用に捕捉し、ログへ表示します。'),
              const SizedBox(height: 24),
              for (final profile in [false, true]) ...[
                if (profile) ...[
                  Text(
                    '② Provider より長生きする関数',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Text('関数を read で取得 → 破棄を待つ → 関数を呼ぶ。画面遷移なしで比較できます。'),
                  Wrap(
                    spacing: 12,
                    children: [
                      for (final safe in [false, true])
                        FilledButton.tonal(
                          onPressed: () async {
                            final action = safe
                                ? ref.read(safeActionProvider)
                                : ref.read(unsafeActionProvider);
                            log.add(safe ? '修正後の関数を取得' : '修正前の関数を取得');
                            await Future<void>.delayed(
                              const Duration(milliseconds: 200),
                            );
                            try {
                              action();
                            } catch (error) {
                              log.add(
                                '例外: ${error.toString().split('\n').first}',
                              );
                            }
                          },
                          child: Text(safe ? '修正後を実行' : '修正前を実行'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                Text(
                  profile ? '③ 保存と共有キャッシュ' : '① await 中の画面離脱',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Text('画面を開く → 処理を開始 → 2 秒以内に「画面を閉じる」'),
                Wrap(
                  spacing: 12,
                  children: [
                    for (final safe in [false, true])
                      FilledButton.tonal(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                DetailPage(safe: safe, profile: profile),
                          ),
                        ),
                        child: Text(safe ? '修正後を開く' : '修正前を開く'),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              Row(
                children: [
                  const Expanded(
                    child: Text('実行ログ', style: TextStyle(fontSize: 22)),
                  ),
                  TextButton(onPressed: log.clear, child: const Text('ログを消す')),
                ],
              ),
              ValueListenableBuilder<List<String>>(
                valueListenable: log,
                builder: (_, entries, _) => SelectableText(
                  entries.isEmpty ? '上のボタンから操作してください。' : entries.join('\n'),
                  style: const TextStyle(fontFamily: 'monospace', height: 1.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
