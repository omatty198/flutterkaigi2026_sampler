# Riverpod 3 · Ref の寿命

Riverpod 3 への移行で起きやすい、破棄済み Ref へのアクセスを再現する Flutter サンプルです。
同じ操作を「修正前」「修正後」で比較し、Provider の破棄と処理の完了を画面上のログで確認できます。

すべて模擬データで動作します。外部 API、アカウント登録、API キーは不要です。
意図的に不具合を含む教材なので、修正前のコードをそのまま製品へ組み込まないでください。

## 起動する

検証環境は **Flutter 3.47.1 / Dart 3.13.1 / flutter_riverpod 3.4.3** です。
Flutter SDK と Chrome を用意して実行してください。

```sh
git clone https://github.com/omatty198/flutterkaigi2026_sampler.git
cd flutterkaigi2026_sampler
# PR のレビュー中はこのブランチを使用。main へのマージ後は不要です。
git switch codex/riverpod-ref-lifecycle
flutter pub get --enforce-lockfile
flutter run -d chrome
```

別のブラウザーで試す場合は、次のコマンドで表示される URL を開きます。

```sh
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8010
```

iOS / Android のプロジェクトも含みますが、動作確認済みなのは Web です。
iOS の実機実行には、利用者自身の署名設定が必要です。ストア配布用の設定は含みません。

## 3 つの比較

### ① await 中の画面離脱

「修正前を開く」→「読み込みを開始」→ **2 秒以内**に「画面を閉じる」の順に操作します。

- 修正前：通信完了後、破棄済みの Notifier の `state` を更新して例外になります。
- 修正後：`ref.mounted` を確認し、画面用の状態更新を省略します。

画面を閉じずに待つと、どちらも商品一覧を表示します。
比較する実装は [items.dart](lib/src/scenarios/items.dart) です。

### ② Provider より長生きする関数

「修正前を実行」「修正後を実行」を順に押します。取得した関数を 200 ms 後に呼び出します。

- 修正前：`read` では購読を維持できず、autoDispose 後に関数内の Ref を使って例外になります。
- 修正後：自動破棄しない Provider に変更し、関数の実行を完了します。

手書きの `Provider` は、`autoDispose` を付けなければ監視がなくても自動破棄されません。
コード生成を使う場合は `@Riverpod(keepAlive: true)` に相当します。
再計算や ProviderContainer の破棄で古い Ref は無効になるため、永久に使えるという意味ではありません。
比較する実装は [callbacks.dart](lib/src/scenarios/callbacks.dart) です。

### ③ 保存と共有キャッシュ

「修正前を開く」→「保存を開始」→ **2 秒以内**に「画面を閉じる」の順に操作します。

- 修正前：サーバーへの保存後、mounted ガードの `return` により共有キャッシュ更新まで省略します。
- 修正後：画面とは独立したサービスで保存とキャッシュ更新を完了し、画面用の状態更新だけを省略します。

画面を閉じずに待つと、どちらもキャッシュを更新して「保存しました」と表示します。
比較する実装は [profile.dart](lib/src/scenarios/profile.dart) です。

## コードを読む・検証する

- `lib/main.dart`：アプリの起動。
- `lib/src/scenarios/`：3 つの比較と、共通のログ・模擬待機処理。
- `lib/src/ui/`：操作画面と実行ログ。
- `test/`：正常完了、破棄後、再計算後、画面操作の回帰テスト。

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web
```

GitHub Actions でも同じ手順を実行します。依存関係の再現性のため、`pubspec.lock` を追跡しています。

## サンプルの前提

- 修正前の例外は比較用に捕捉してログへ表示します。製品で例外を握りつぶすことを推奨するものではありません。
- `ref.mounted` は通信のキャンセルや、複数リクエストの競合を防ぐ仕組みではありません。
- 画面離脱後の継続は、アプリが動作し、サービスと依存オブジェクトが有効な間を扱います。
- アプリ終了後の完了保証、通信失敗時の再試行、実際の永続化は対象外です。

参考：[Riverpod 3 移行ガイド](https://riverpod.dev/ja/docs/3.0_migration)、[自動破棄](https://riverpod.dev/docs/concepts2/auto_dispose)。

## ライセンス

[MIT License](LICENSE)。
