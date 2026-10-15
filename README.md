# Riverpod 3：Ref と Provider の寿命

技術記事の問題と対策を、実際の画面操作とログで比較する Flutter サンプルです。
通信はすべて模擬処理で、外部 API や認証情報は使いません。

## 実行

Flutter 3.47.1 / Dart 3.13.1、flutter_riverpod 3.4.3 で検証しています。

```sh
flutter pub get
flutter run -d chrome
```

Web サーバーで実行する場合：

```sh
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8010
```

表示された URL をブラウザーで開いてください。iOS / Android の雛形も含みますが、実機での検証は未実施です。

## 比較する操作

1. **await 中の画面離脱**：修正前の画面を開き、「読み込みを開始」を押して 2 秒以内に画面を閉じると、ログに破棄済み Ref の例外が出ます。修正後は `ref.mounted` で表示更新を省略します。
2. **Provider より長生きする関数**：それぞれの実行ボタンを押すと、関数の取得から 200 ms 待って呼び出します。修正前は autoDispose により失敗し、修正後は購読なしでも自動破棄しないため成功します。
3. **保存と共有キャッシュ**：保存開始後、2 秒以内に画面を閉じます。修正前は保存後の return で共有キャッシュ更新まで止まります。修正後はサービスで保存とキャッシュ更新を完了し、画面の表示更新だけを省略します。

画面を閉じずに待つと、商品一覧と保存完了表示の正常系も確認できます。
修正前の例外は比較用に捕捉してログへ表示します。実際のアプリで例外を握りつぶす方針を推奨するものではありません。

## ソースと検証

- `lib/scenarios.dart`：Provider、修正前後の処理、模擬サービス。
- `lib/main.dart`：操作画面と実行ログ。
- `test/`：通常完了・破棄後・コールバック・画面表示のテスト。

```sh
flutter analyze
flutter test
```

手書きの `Provider` はデフォルトで自動破棄されないため、修正後の関数は `Provider.autoDispose` から `Provider` に変更しています。
コード生成なら `@Riverpod(keepAlive: true)` に相当します。
再計算や ProviderContainer の破棄では古い Ref は無効になるため、keepAlive は永久に使える保証ではありません。

共有サービスは画面の Provider と独立して保持しています。アプリ終了後の処理継続や通信失敗時の再試行は、このサンプルの対象外です。
