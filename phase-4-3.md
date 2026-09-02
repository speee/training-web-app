# Phase 4.3: Controller / Action 構造をTDDで実装する

[← 前へ: Phase 4.2](./phase-4-2.md) | [目次](./README.md#カリキュラムテキスト) | [次へ: Phase 4.4 →](./phase-4-4.md)

## 概要

実行前に[共通セットアップと各Phaseの確認手順](./SETUP.md#4-各phaseの実行と引き継ぎ)を確認してください。演習コードは`work/`で前のPhaseから引き継ぎます。

このフェーズでは、Phase 4-2で作成したルータの次のステップとして、**Controller / Action 構造** をTDD（テスト駆動開発）で導入します。

Phase 4.2では、ルータによって

- HTTPメソッド
- パス

に応じて処理を振り分けることができるようになりました。

しかし現状では、ルータの行き先は多くの場合

- Proc
- ラムダ

などの無名の処理になっているはずです。

このままアプリケーションが大きくなると、

- 関連する処理が散らばる
- 同じ種類の処理をまとめられない
- 共通処理を入れる場所がない
- アプリケーションコードを書く場所が曖昧になる

という問題が起きます。

このフェーズでは、それを解決するために

> 「関連する処理を Controller という単位でまとめる」

構造を導入します。

なお、このフェーズでは必ず  
**RED → GREEN → REFACTOR**  
の流れで進めてください。

---

## このフェーズの目的

以下を説明できる状態になること：

- Controller とは何か
- Action とは何か
- なぜ Proc ではなくクラス + メソッドにするのか
- Router と Controller の責務の違い
- なぜ ControllerBase が必要になるのか

---

## 到達目標

- Router から Controller / Action を呼び出せる
- `"users#index"` のような指定を扱える
- Controller から params を参照できる
- `ControllerBase` に共通処理を集約できる
- TDD で設計を進められる

---

## 前提

- [Phase 4.2](./phase-4-2.md)（ルーティングのTDD実装）完了
- Minitest を使ってテストを書けること

---

## 重要ルール

このフェーズでは、以下を必ず守ってください。

### 1. 実装より先にテストを書く
### 2. 失敗することを確認する（RED）
### 3. 最小の実装で通す（GREEN）
### 4. テストを壊さずに整理する（REFACTOR）

---

## 演習課題

---

## Step 1: Proc の代わりに Controller を呼びたいというテストを書く（RED）

まず、Router の行き先として Proc ではなく Controller を使いたい、という失敗テストを書きます。

### テスト例

```ruby
def test_routes_to_controller_action
  router = Router.new
  router.get "/users", to: UsersController.action(:index)

  status, _, body = router.call(env_for("/users"))

  assert_equal 200, status
  assert_equal ["Users Index"], body
end
````

```ruby
class UsersController
  def index
    [200, {}, ["Users Index"]]
  end
end
```

### 状態

* `UsersController.action(:index)` がまだ存在しない
* 失敗してよい

👉 これが RED

---

## Step 2: 最小の実装で Controller の Action を呼び出す（GREEN）

### やること

* `UsersController.action(:index)` が呼べるようにする
* Router からその handler を実行できるようにする

### ポイント

* 最初はベタでもよい
* まだ汎用的でなくてよい
* まずは1つの Action が動けばよい

---

## Step 3: 複数 Action を扱うテストを書く（RED）

次に、同じ Controller に複数の Action を持たせます。

### テスト例

```ruby
def test_routes_to_different_actions_in_same_controller
  router = Router.new
  router.get "/users", to: UsersController.action(:index)
  router.get "/users/show", to: UsersController.action(:show)

  status1, _, body1 = router.call(env_for("/users"))
  status2, _, body2 = router.call(env_for("/users/show"))

  assert_equal 200, status1
  assert_equal ["Users Index"], body1
  assert_equal 200, status2
  assert_equal ["Users Show"], body2
end
```

### 状態

* まだ複数 Action を自然に扱えないなら失敗する

👉 RED

---

## Step 4: `"users#index"` 形式を先にテストで固定する（RED）

ここで、よりフレームワークらしい記法を導入します。

### テスト例

```ruby
def test_routes_with_controller_action_string
  router = Router.new
  router.get "/users", to: "users#index"

  status, _, body = router.call(env_for("/users"))

  assert_equal 200, status
  assert_equal ["Users Index"], body
end
```

### 課題

* `"users#index"` をどう解釈するか
* `"users"` をどう `UsersController` に変換するか
* `index` をどう呼ぶか

### 状態

* まだ文字列指定を解決できないはず

👉 RED

---

## Step 5: 文字列指定を解決する最小実装を書く（GREEN）

### やること

* `"users#index"` を分解する
* 対応する Controller クラスを見つける
* Action メソッドを呼ぶ

### ヒント

* 文字列操作
* `capitalize`
* `const_get`

### 注意

* 最初から複雑な命名規則に対応しなくてよい
* 今必要な範囲だけでよい

---

## Step 6: params を Controller から参照したいというテストを書く（RED）

Controller を導入した以上、Action の中から request 情報を扱いたくなります。

### テスト例

```ruby
def test_controller_can_access_params
  router = Router.new
  router.get "/users/:id", to: "users#show"

  status, _, body = router.call(env_for("/users/42"))

  assert_equal 200, status
  assert_equal ["42"], body
end
```

```ruby
class UsersController
  def show
    [200, {}, [params["id"]]]
  end
end
```

### 状態

* `params` がまだないので失敗するはず

👉 RED

---

## Step 7: Controller に request / params を渡す最小実装を書く（GREEN）

### やること

* Controller 初期化時に `env` あるいは request 情報を渡す
* Controller の中で `params` を参照できるようにする

### 考えるべきこと

* `initialize(env)` にするか
* `initialize(req)` にするか
* params をメソッドで返すか

---

## Step 8: 共通化したくなる失敗を観察する

ここで複数 Controller を追加してみてください。

### 例

* `UsersController`
* `PostsController`

### 観察ポイント

* 毎回 `initialize` や `params` を書いていないか
* 共通処理が重複していないか

### 気づき

> 「Controller の共通処理をまとめるベースクラスが必要」

---

## Step 9: ControllerBase を先に使うテストを書く（RED）

### テスト用コード例

```ruby
class ControllerBase
end

class UsersController < ControllerBase
  def show
    [200, {}, [params["id"]]]
  end
end
```

### 課題

* `ControllerBase` に `params` を持たせたい
* 子クラスから利用できるようにしたい

### 状態

* まだ何もないので失敗する

👉 RED

---

## Step 10: ControllerBase に共通処理を移す（GREEN）

### やること

* request / params の初期化を `ControllerBase` に集約する
* 各 Controller は継承するだけでよい状態にする

---

## Step 11: dispatch 経路を整理する（REFACTOR）

ここまで来ると、Controller の呼び出し手順が見えてきます。

例えば：

1. Controller を生成する
2. Action を呼ぶ
3. 戻り値を Rack レスポンスにする

この一連の流れを整理してください。

### 課題

* `action` クラスメソッドに閉じ込めるか
* `dispatch` インスタンスメソッドを作るか
* どこまでを Router にやらせるか

### 目標

Router が Controller の詳細を知りすぎないようにすること

---

## Step 12: 存在しない Controller / Action の扱いを考える

### テスト候補

* 存在しない Controller 名
* 存在しない Action 名

### 課題

* 例外にするか
* 404にするか
* どの層で扱うか

※ この時点では簡易な実装でよい

---

## 提出物

### 1. テストコード

最低限、以下を含むこと：

* Controller Action を呼び出せる
* 同一 Controller の複数 Action を扱える
* `"users#index"` 形式を扱える
* Controller から params を参照できる
* `ControllerBase` に共通処理を集約できる

### 2. 実装コード

* Router
* ControllerBase
* サンプル Controller

### 3. 設計メモ

以下について説明してください：

* Proc ではなく Controller が必要な理由
* Router と Controller の責務の違い
* `ControllerBase` を導入した理由
* テストによって設計がどう決まったか

---

## レビュー観点

* RED → GREEN → REFACTOR を守れているか
* テストが仕様として機能しているか
* Controller の責務を理解しているか
* Router が Controller の詳細を抱え込みすぎていないか
* 共通処理の抽出が適切か

---

## AI活用

### OK

* テストの粒度の相談
* Rubyの `const_get` などの確認
* 責務分離の壁打ち

### NG

* 実装の生成
* 完成コードの出力
* 解答の丸写し

---

## よくある失敗

### 1. 最初から完成形を作ろうとする

→ まずは1つの失敗テストから始めること

### 2. Router に Controller 解決の詳細を詰め込みすぎる

→ Router は「行き先を呼ぶ」ことに集中する

### 3. ControllerBase を早く入れすぎる

→ 重複が見えてから導入すること

### 4. テストより先に設計を確定してしまう

→ テストから必要性を引き出すこと

---

## このフェーズの本質

このフェーズで得るべき理解は、

> フレームワークとは、
> 「アプリケーションコードをどこに、どう書かせるか」を定義する仕組みである

ということです。

Controller の導入は、単にクラスを増やすことではありません。

それは、

* 関連する処理をまとめ
* 共通処理を差し込めるようにし
* アプリケーションの構造を規定する

ための重要な一歩です。

---

## 次フェーズへの接続

Controller / Action 構造ができると、次の問題が見えてきます。

* Action の中で毎回 Rack レスポンス配列を書くのがつらい
* redirect をどう表現するのか
* HTTP の詳細が Action に漏れている

次のフェーズでは、これを解決するために

> render / redirect

を導入します。

---

## 最後に

Controller を導入すると、アプリケーションは「動く」だけでなく、**構造を持ち始めます。**

ここでは完成度よりも、

* どんな失敗テストを書いたか
* どの順序で抽象化したか
* 何を共通化すべきだと気づいたか

を重視してください。

---

[← 前へ: Phase 4.2](./phase-4-2.md) | [目次](./README.md#カリキュラムテキスト) | [次へ: Phase 4.4 →](./phase-4-4.md)
