# Phase 5.3: Consoleモードを実装する — 自作ORMを対話的に検証する

[← 前へ: Phase 5.2](./phase-5-2.md) | [目次](./README.md#カリキュラムテキスト) | [次へ: Phase 5.4 →](./phase-5-4.md)

## 概要

実行前に[共通セットアップと各Phaseの確認手順](./SETUP.md#4-各phaseの実行と引き継ぎ)を確認してください。演習コードは`work/`で前のPhaseから引き継ぎます。

このフェーズでは、Phase 5.2で導入した Model を、
WebブラウザやControllerを経由せずに対話的に扱える
**Consoleモード** を実装します。

Phase 5.2の時点で、`User.all` や `User.find` は動作しているはずです。

しかし、それらを確認するために毎回HTTPリクエストを発生させたり、
ControllerやViewを経由したりしていると、Model単体の挙動が見えにくくなります。

このフェーズでは、それを解決するために、

> 「自作ORMを対話的に検証できる入口」

として、最小限のConsoleモードを作ります。

Railsにおける `rails console` がなぜ重要なのかも、
このフェーズを通じて理解できるようになります。

---

## このフェーズの目的

以下を説明できる状態になること：

- Consoleモードとは何か
- なぜWebリクエストなしでModelを触りたいのか
- なぜORMの検証に対話環境が向いているのか
- Rails console が何をしているのか
- テストとConsoleの役割の違い

---

## 到達目標

- `bin/console` のような起動スクリプトを持てる
- アプリケーションコードを読み込んだ状態でIRBを起動できる
- Console上で `User.all` / `User.find` を試せる
- Controllerを経由せずにModelの挙動を確認できる
- 今後のORM開発でConsoleを検証ツールとして使える

---

## 前提

- Phase 5.2（1テーブル専用Model）完了
- `User.all`, `User.find` が動作している
- DB接続がアプリケーション内で使える状態

---

## 重要ルール

### 1. 独自REPLを作らない
### 2. Rubyの対話環境IRBを使う
### 3. ConsoleはORMを検証するための入口とする
### 4. 便利機能より「読み込みの仕組み」を理解する

Ruby 4ではBundler経由でIRBを読み込めるよう、Gemfileに`gem "irb"`を記載します。演習用Gemfileには追加済みです。

---

## このフェーズで目指す最終形（イメージ）

```bash
bin/console
```

Console起動後：

```ruby
User.all
User.find(1)
```

※ このフェーズでは、まだ高度なORM機能は前提にしません
※ `where`, `save`, `validation` などは後続フェーズで扱います

---

# 演習課題

---

## Step 1: Consoleが必要になる理由を考える

まずは、なぜConsoleがあると便利なのかを整理します。

### 課題

以下を考察してください：

- なぜブラウザを開かずにModelを触りたいのか？
- なぜControllerを通さずに `User.all` を試したいのか？
- Webリクエストなしで検証できる価値は何か？

### 気づき

> ModelやORMの挙動を確認したいだけなら、HTTPの流れ全体は不要

---

## Step 2: 最小のConsole起動スクリプトを作る

まずは、IRBを起動するだけのスクリプトを作ってください。

### 目標

以下のようなコマンドで起動できること：

```bash
bin/console
```

### ヒント

- Ruby標準の `IRB` を利用できる
- `bin/console` は実行可能ファイルにする必要がある
- 最初はアプリケーションコードを読み込めなくてもよい

### 注意

このフェーズでは独自REPLを作る必要はありません。

---

## Step 3: アプリケーションコードを読み込む

Console起動時に、Phase 5.2までで作ったModelを利用できる状態にしてください。

### 目標

Console起動後に以下を評価できること：

```ruby
User
```

### 考えること

- `User` クラスはどのファイルに定義されているか？
- `require_relative` はどのパスから解決されるか？
- アプリケーションの初期化処理はどこに集約されているか？

---

## Step 4: DB接続を含めて読み込む

`User` クラスだけでなく、DB接続も使える状態にしてください。

### 確認

Console起動後に以下を試してください：

```ruby
User.all
User.find(1)
```

### 問い

- DB接続はConsole起動時に準備されているか？
- Webリクエスト時と同じ接続設定を使えているか？
- テストDBと開発DBをどう区別するか？

---

## Step 5: Controller経由との違いを観察する

同じ `User.all` を、Controller経由とConsole経由で比較してください。

### 観察ポイント

- Controllerが担当していること
- Modelが担当していること
- Consoleから直接見えること
- Web画面だけでは見えにくいこと

### 気づき

> Consoleを使うと、Modelの責務だけを切り出して観察できる

---

## Step 6: ORMの違和感をConsoleで発見する

Console上で、今の `User.all` / `User.find` の戻り値を詳しく観察してください。

### 課題

以下を試してください：

```ruby
users = User.all
user = User.find(1)

users.class
user.class
```

### 問い

- `User.all` の戻り値は自然か？
- `User.find(1)` の戻り値は「Userらしい」か？
- `user["name"]` のようなアクセスに違和感はないか？

### 次への接続

ここで出てくる違和感が、次のフェーズで扱う
「レコードをオブジェクトとして扱う」動機になります。

---

## Step 7: Consoleを今後の検証手順に組み込む

このPhaseで作るConsoleは、この先のORM開発で継続して使います。

### ガイダンス

Phase 5.4以降では、新しい機能を実装するたびに、
テストだけでなくConsoleでも実際に触ってください。

例：

- Phase 5.4: `user.name` が自然に使えるか確認する
- Phase 5.5: `User.where(name: "Alice")` のAPIが自然か確認する
- Phase 5.6: `user.save` 後にDBが変化するか確認する
- Phase 5.7: validation error を対話的に確認する
- Phase 5.8: BaseModel化しても `User.all` が壊れていないか確認する

### 注意

Consoleはテストの代替ではありません。

ただし、APIの使いやすさ、違和感、設計の粗さを発見するための
重要な道具です。

---

## Step 8: Rails console と比較する

実際に Rails console が何をしているか調べてください。

### 観察ポイント

- なぜ `User.all` がすぐ使えるのか？
- Console起動時に何が読み込まれているか？
- IRB単体と何が違うのか？

### 問い

- Rails console は単なるIRBか？
- アプリケーション環境とは何か？

---

## Step 9: 「対話的に触れる価値」を言語化する（最重要）

以下を説明してください：

- Consoleは何のためにあるのか
- なぜORMと相性が良いのか
- なぜConsoleはテストの代替ではないのか
- なぜ今後のORM開発でConsoleを使い続けるのか

---

# このフェーズの本質

このフェーズで得るべき理解は：

> Consoleは便利機能ではなく、
> 自作したModelやORMを開発者として対話的に検証するための入口である

---

# 次フェーズへの接続

Consoleで `User.all` や `User.find` を触ると、必ず次の違和感が出ます：

- 戻り値がただの配列やハッシュに見える
- `user["name"]` のようなアクセスが気持ち悪い
- 「User」と言っているのにRubyオブジェクトらしくない

次のフェーズではこれを解決します：

👉 **Phase 5.4: レコードをオブジェクトとして扱う（ORMの核心）**

---

[← 前へ: Phase 5.2](./phase-5-2.md) | [目次](./README.md#カリキュラムテキスト) | [次へ: Phase 5.4 →](./phase-5-4.md)
