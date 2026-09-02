# Phase 4.2: ルーティングをTDDで実装する

[← 前へ: Phase 4.1](./phase-4-1.md) | [目次](./README.md#カリキュラムテキスト) | [次へ: Phase 4.3 →](./phase-4-3.md)

## 概要

実行前に[共通セットアップと各Phaseの確認手順](./SETUP.md#4-各phaseの実行と引き継ぎ)を確認してください。演習コードは`work/`で前のPhaseから引き継ぎます。

このフェーズでは、Phase 3.2で学んだテストを活用し、

> ルーティング機能を **TDD（テスト駆動開発）で実装**

します。

これまでと違い、

- ❌ 実装してからテストを書く
- ❌ 動けばOK

ではなく、

> ✅ 先に振る舞いを定義し  
> ✅ それを満たす最小の実装を書く

という流れで進めます。

---

## このフェーズの目的

- 振る舞いを先に定義する力を身につける
- 小さな単位で設計する習慣を身につける
- RED → GREEN → REFACTOR を実践する
- フレームワーク実装を「テスト可能な設計」で進める

---

## 到達目標

- Routerの振る舞いをテストで定義できる
- テストを通す最小実装ができる
- テストを壊さずにリファクタリングできる

---

## 前提

- [Phase 3.2](./phase-3-2.md)（テスト / 並行性）完了
- [Phase 4.1](./phase-4-1.md)（素のRackアプリの限界）完了
- Minitestが使える

---

# 🚨 重要ルール

このフェーズでは必ず以下を守ること：

### 1. 実装より先にテストを書く
### 2. テストが失敗することを確認する（RED）
### 3. 最小の実装で通す（GREEN）
### 4. コードを整理する（REFACTOR）

---

# 演習課題

---

## Step 1: Routerが存在しない状態から始める（RED）

まず、Routerがまだ存在しない状態でテストを書きます。

---

### テストを書く

```ruby
def test_get_root_returns_200
  router = Router.new

  router.get "/" do |_req|
    [200, {}, ["OK"]]
  end

  status, _, body = router.call(env_for("/"))

  assert_equal 200, status
  assert_equal ["OK"], body
end
````

---

### 状態

* Routerがないのでエラーになるはず

👉 **これが正しい（RED）**

---

## Step 2: 最小実装で通す（GREEN）

---

### やること

* Routerクラスを作る
* `get` と `call` を最低限実装

---

### 注意

* まだ汎用化しない
* if文ベタ書きでOK

---

## Step 3: 2つ目のルートを追加（RED）

---

### テスト追加

```ruby
def test_get_users
  router = Router.new

  router.get "/" do |_req|
    [200, {}, ["root"]]
  end

  router.get "/users" do |_req|
    [200, {}, ["users"]]
  end

  status, _, body = router.call(env_for("/users"))

  assert_equal ["users"], body
end
```

---

### 状態

* 失敗するはず（RED）

---

## Step 4: 通す（GREEN）

---

### やること

* ルートを複数持てるようにする

---

## Step 5: REFACTOR

---

### やること

* 配列 or ハッシュに整理
* 重複コード削除

---

## Step 6: HTTPメソッドを考慮する（RED）

---

### テスト追加

```ruby
def test_post_users
  router = Router.new

  router.post "/users" do |_req|
    [200, {}, ["created"]]
  end

  status, _, body = router.call(env_for("/users", method: "POST"))

  assert_equal ["created"], body
end
```

---

## Step 7: 通す（GREEN）

---

### やること

* methodも条件に含める

---

## Step 8: 404を定義する（RED）

---

### テスト追加

```ruby
def test_returns_404_when_not_found
  router = Router.new

  status, _, _ = router.call(env_for("/unknown"))

  assert_equal 404, status
end
```

---

## Step 9: 通す（GREEN）

---

## Step 10: 動的ルート（RED）

---

### テスト追加

```ruby
def test_dynamic_route
  router = Router.new

  router.get "/users/:id" do |req|
    id = req.path_params["id"]
    [200, {}, [id]]
  end

  status, _, body = router.call(env_for("/users/42"))

  assert_equal ["42"], body
end
```

---

## Step 11: 通す（GREEN）

---

### やること

* pathのパターンマッチ
* param抽出

---

## Step 12: REFACTOR（重要）

---

### やること

* 正規表現化
* match処理分離
* Routerの責務整理

---

# 提出物

---

## 1. Routerの実装

---

## 2. テストコード

以下を含む：

* 静的ルート
* 複数ルート
* メソッド分岐
* 404
* 動的ルート

---

## 3. 設計メモ

以下を説明：

* テストから設計がどう決まったか
* 最初に書いたテストは何を固定したか
* リファクタリングで何を改善したか

---

# レビュー観点

* RED → GREEN → REFACTOR を守っているか
* テストが仕様になっているか
* 実装が最小か
* リファクタリングしているか

---

# AI活用

## OK

* テストの書き方相談
* 設計の壁打ち

## NG

* 実装生成

---

# よくある失敗

---

## ❌ 最初から完成形を作る

→ TDDの意味が消える

---

## ❌ テストを書き直す

→ 仕様を変えている

---

## ❌ REFACTORをやらない

→ 技術負債になる

---

# このフェーズの本質

このフェーズで得るべきものは：

> フレームワークは「実装」ではなく「振る舞いの集合」である

---

# 次フェーズへの接続

ここまで来ると自然に次の疑問が出ます：

* handlerがProcでいいのか？
* 複数処理をどうまとめるのか？

👉 次は Controller を導入する

---

[← 前へ: Phase 4.1](./phase-4-1.md) | [目次](./README.md#カリキュラムテキスト) | [次へ: Phase 4.3 →](./phase-4-3.md)
