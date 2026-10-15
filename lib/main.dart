import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'scenarios.dart';

void main() => runApp(const ProviderScope(child: SampleApp()));

class SampleApp extends StatelessWidget {
  const SampleApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Riverpod 3 Ref の寿命',
    theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
    home: const Home(),
  );
}

class Home extends ConsumerWidget {
  const Home({super.key});
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
                                Detail(safe: safe, profile: profile),
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

class Detail extends ConsumerWidget {
  const Detail({super.key, required this.safe, required this.profile});
  final bool safe;
  final bool profile;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.read(logProvider);
    final items = safe ? safeItemsProvider : unsafeItemsProvider;
    final account = safe ? safeProfileProvider : unsafeProfileProvider;
    final status = profile ? ref.watch(account) : ref.watch(items).join('、');
    return Scaffold(
      appBar: AppBar(
        title: Text('${safe ? "修正後" : "修正前"} · ${profile ? "保存" : "商品一覧"}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(status.isEmpty ? '商品はまだありません' : status),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                try {
                  if (profile) {
                    await ref.read(account.notifier).save();
                  } else {
                    await ref.read(items.notifier).reload();
                  }
                } catch (error) {
                  log.add('例外: ${error.toString().split('\n').first}');
                }
              },
              child: Text(profile ? '保存を開始（2秒）' : '読み込みを開始（2秒）'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('画面を閉じる'),
            ),
          ],
        ),
      ),
    );
  }
}
