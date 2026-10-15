import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../scenarios.dart';

class DetailPage extends ConsumerWidget {
  const DetailPage({super.key, required this.safe, required this.profile});
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
