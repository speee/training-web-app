# Phase 3.1: 抽象化の導入（Rack）演習

[← 前へ: Phase 2](./phase-2.md) | [目次](./README.md#カリキュラムテキスト) | [次へ: Phase 3.2 →](./phase-3-2.md)

## 概要

実行前に[共通セットアップと各Phaseの確認手順](./SETUP.md#4-各phaseの実行と引き継ぎ)を確認してください。演習コードは`work/`で前のPhaseから引き継ぎます。

このフェーズでは、RubyにおけるWebアプリケーションの標準インターフェースである[Rack 3.2](https://github.com/rack/rack/blob/v3.2.7/SPEC.rdoc)を理解し、自作HTTPサーバをRack対応させます。

[Phase 1](./phase-1.md)で「低レイヤー」を理解し、
[Phase 2](./phase-2.md)で「実務コード」を読んだ上で、

本フェーズでは：

> 「なぜ抽象化が必要なのか」  
> 「抽象化とは何をしているのか」

を体験的に理解します。

---

## このフェーズの目的

以下を説明できる状態になること：

- Webサーバとアプリケーションの責務の違い
- Rackインターフェースの役割
- なぜインターフェースが必要なのか
- 抽象化によって何が得られるのか

---

## 到達目標

- Rackアプリケーションの仕様を理解する
- Rackアプリを自分で実装できる
- 自作HTTPサーバをRack対応させる
- Webサーバとアプリケーションを分離できる

---

## 前提

- [Phase 1](./phase-1.md)（HTTPサーバ実装）完了
- [Phase 2](./phase-2.md)（WEBrick読解）完了
- [セットアップガイド](./SETUP.md)で作成した`work/`で`bundle install`を実行済みであること

この教材で使用する`rack`、`rackup`、`webrick`は`Gemfile`に記載されています。Rack 3ではサーバ起動コマンドとHandlerが`rack` Gem本体から`rackup` Gemへ分離されたため、3つのGemを明示的に導入します。詳細は[Rack 3 Upgrade Guide](https://github.com/rack/rack/blob/v3.2.7/UPGRADE-GUIDE.md)を参照してください。

---

## 重要な前提

このフェーズで扱うのは「フレームワーク」ではありません。

> Rackは「約束（インターフェース）」である

---

## 演習課題

### Step 1: Rackアプリを書いてみる

まずは最小のRackアプリを作成します。

```ruby
app = Proc.new do |env|
  [200, { "content-type" => "text/plain" }, ["Hello Rack"]]
end
```

Rack 3のレスポンスヘッダ名には、小文字だけを使用します。大文字を含む`Content-Type`ではなく`content-type`と書いてください。このルールを含む正確なインターフェースは[Rack 3.2.7 SPEC](https://github.com/rack/rack/blob/v3.2.7/SPEC.rdoc)で確認できます。

#### 課題

- `env` とは何か？
- 配列 `[200, headers, body]` の意味は何か？

---

### Step 2: Rackの構造を理解する

Rackアプリの仕様：

```
call(env) → [status, headers, body]
```


#### 課題

以下を説明する：

- なぜこの形になっているのか？
- なぜオブジェクトではなく配列なのか？

---

### Step 3: Rackを使ってサーバを起動する

`config.ru`を作成します。

```ruby
require 'rack'

app = Proc.new do |env|
  [200, { "content-type" => "text/plain" }, ["Hello Rack"]]
end

run app
```

Rack 3では旧来のHandler APIを直接呼び出しません。`rackup` Gemのコマンドから、開発用サーバとしてWEBrickを指定して起動します。

```console
bundle exec rackup -s webrick -o 127.0.0.1 -p 3000 config.ru
```

ブラウザまたは`curl http://localhost:3000/`でレスポンスを確認し、終了するときは`Ctrl-C`を押します。開発環境の`rackup`は`Rack::Lint`を含む検証用ミドルウェアを自動的に適用し、レスポンスヘッダ名などがRack仕様に適合していなければエラーを報告します。教材自体の互換性検査は教材ルートで、演習のテストは`work/`で、それぞれ`bundle exec rake test`を実行します。

#### 観察

- Phase 1との違いは何か？
- サーバとアプリの責務はどう分かれているか？

---

### Step 4: envの中身を調べる

以下を追加：

```ruby
puts env
```

#### 課題

- envにどんな情報が入っているか列挙する
- HTTPリクエストとの対応関係を説明する

---

### Step 5: 自作HTTPサーバをRack対応させる

ここが本フェーズの核心です。

#### 要件

Phase 1で作ったHTTPサーバを改造し：

- Rackアプリを受け取れるようにする
- Rack形式でレスポンスを返す

---

#### やること

1. リクエストからenvを作る
2. Rackアプリを呼び出す
3. 戻り値をHTTPレスポンスに変換する

---

#### 疑似コード

```ruby
env = build_env(request)

status, headers, body = app.call(env)

response = build_http_response(status, headers, body)
```

---

### Step 6: サーバとアプリの分離を実感する

#### 課題

以下を試す：

- アプリだけ差し替える
- サーバは変更しない

#### 例

```ruby
app = Proc.new do |env|
  [200, { "content-type" => "text/html" }, ["<h1>New App</h1>"]]
end
``` 

→ サーバ側は変更不要で動くことを確認

---

## 発展課題

### 課題1: ミドルウェアを実装する

リクエスト前後に処理を挟む

例：

- ログ出力
- 処理時間計測

---

### 課題2: ルーティングを自作する

- pathに応じて処理を分岐

---

### 課題3: envを自分で設計してみる

- 必要最小限のenvとは何か？

---

## 成果物

以下を提出してください：

### 1. Rack対応HTTPサーバ

- 自作サーバ + Rackインターフェース

### 2. 説明資料

- Rackとは何か
- なぜ必要か
- 何が変わったか

### 3. 比較

- Phase 1との違い
- WEBrickとの関係

---

## レビュー観点

- 抽象化の意味を理解しているか
- サーバとアプリの分離ができているか
- インターフェースの価値を説明できるか
- 「なぜ」を説明できるか

---

## AI活用

### OK

- Rackの仕様の解説
- envの意味の理解
- 設計の壁打ち

### NG

- 実装の生成

---

## よくあるつまずき

### 1. envがわからない

→ HTTPリクエストとの対応を見る

---

### 2. 抽象化の意味がわからない

→ 「差し替え可能性」に注目

---

### 3. 難しく感じる

→ すべて理解する必要はない  
→ 「境界」を理解することが重要

---

## このフェーズの本質

このフェーズで得るべきものは：

> 「仕組みを分離する力」

---

## 最後に

このフェーズを理解すると：

- フレームワークの構造が見える
- 設計の自由度が上がる
- 技術選定の判断ができる

ここが「ジュニア → ミドル」の分岐点です。


## 発展課題: フレームワークはどこでRackを使っているか

この課題では、実際のフレームワークであるSinatraとRailsがどのようにRackを利用しているかを調査します。

これは任意の発展課題です。Sinatra/Railsは基準Gemfileには含みません。[発展課題の環境分離](./SETUP.md#5-発展課題と検証の範囲)に従い、別プロジェクトの依存関係を使ってください。

---

## この課題の目的

- Rackが「実際に使われている抽象」であることを理解する
- フレームワークの構造を分解して理解する
- 「フレームワーク = Rackの上に乗っているもの」と認識する

---

## 調査の進め方

以下の順番で進めてください：

1. 実際に動かす
2. エントリーポイントを特定する
3. Rackとの接点を探す
4. 処理の流れを追う

---

## Part 1: Sinatraの場合

### Step 1: Sinatraを動かす

```ruby
require 'sinatra'

get '/' do
  "Hello Sinatra"
end
```

---

### Step 2: Rackとの接点を探す

#### 課題

以下を調査：

- SinatraアプリはどこでRackアプリになっているか？
- `call(env)` はどこで実装されているか？

---

### Step 3: rackupで起動する

`config.ru` を作成：

```ruby
require './app'
run Sinatra::Application
```

#### 課題

- `run` とは何か？
- なぜこれで起動できるのか？

---

### Step 4: 構造を説明する

以下を説明：

- SinatraはRackの何を実装しているのか？
- 自作Rackアプリとの共通点は何か？

---

## Part 2: Railsの場合

### Step 1: Railsアプリを確認

Railsアプリには必ず以下が存在します：

---

[← 前へ: Phase 2](./phase-2.md) | [目次](./README.md#カリキュラムテキスト) | [次へ: Phase 3.2 →](./phase-3-2.md)
