# Phase 4.7: 共通処理（before_action / Middleware的仕組み）をTDDで導入する

[← 前へ: Phase 4.6](./phase-4-6.md) | [目次](./README.md#カリキュラムテキスト) | [次へ: Phase 5.1 →](./phase-5-1.md)

## 概要

実行前に[共通セットアップと各Phaseの確認手順](./SETUP.md#4-各phaseの実行と引き継ぎ)を確認してください。演習コードは`work/`で前のPhaseから引き継ぎます。

このフェーズでは、これまでに構築してきた自作Webフレームワークに対して、

- 共通処理
- 前処理
- 横断的関心事

を扱う仕組みを **TDD（テスト駆動開発）で導入**します。

Phase 4.6までで、以下は揃っています：

- Routing
- Controller / Action
- render / redirect
- View / Template
- Request / Params

しかし現状では、次のような問題が出てきているはずです。

- ログ出力を各Actionに書いている
- 認証チェックを各Actionに書いている
- 同じ前処理が何度も出てくる
- エラー処理が分散している

このフェーズでは、それを解決するために、

> Actionの前後に処理を差し込める仕組み

を導入します。

---

## このフェーズの目的

以下を説明できる状態になること：

- なぜ共通処理を分離したくなるのか
- before_actionとは何か
- Middleware的な発想とは何か
- Controllerの責務と共通処理の境界
- 処理の流れ（パイプライン）という考え方

---

## 到達目標

- Controllerに共通処理を差し込める
- Actionの前に処理を実行できる
- 特定のActionにだけ適用できる
- 複数の共通処理を順序付きで適用できる
- 処理の流れをコントロールできる（中断など）
- TDDで拡張ポイントを設計できる

---

## 前提

- [Phase 4.6](./phase-4-6.md)（Request / Params）完了
- Minitest を使えること

---

## 重要ルール

### 1. 必ずテストから書く（RED）
### 2. 最小実装で通す（GREEN）
### 3. 設計を整理する（REFACTOR）

---

# 演習課題

---

## Step 1: Action内に共通処理が重複する状況を作る

まずは「痛み」を作ります。

### 課題

以下のようなControllerを書く：

```ruby
class UsersController < ControllerBase
  def index
    log("start index")
    render_text "index"
  end

  def show
    log("start show")
    render_text "show"
  end

  private

  def log(msg)
    # 何かログ出力
  end
end
````

### 観察

* 同じ処理を繰り返している
* Actionの本質と関係ない処理が混ざっている

### 気づき

> 「Actionの外に出したい」

---

## Step 2: Actionの前に処理を差し込みたいというテストを書く（RED）

### テスト例

```ruby
def test_before_action_runs_before_action_method
  controller = UsersController.new(env_for("/users"))

  called = []

  UsersController.before_action do
    called << "before"
  end

  controller.dispatch(:index)

  assert_equal ["before"], called
end
```

```ruby
class UsersController < ControllerBase
  def index
    render_text "index"
  end
end
```

### 状態

* before_action が存在しない

👉 RED

---

## Step 3: 最小の before_action を実装する（GREEN）

### やること

* クラスメソッド `before_action` を追加
* ブロックを保持する
* dispatch前に実行する

### 注意

* まずは1つだけ動けばよい
* 順序やオプションはまだ考えない

---

## Step 4: 複数の before_action を扱うテストを書く（RED）

### テスト例

```ruby
def test_multiple_before_actions_run_in_order
  controller = UsersController.new(env_for("/users"))

  calls = []

  UsersController.before_action { calls << 1 }
  UsersController.before_action { calls << 2 }

  controller.dispatch(:index)

  assert_equal [1, 2], calls
end
```

👉 RED

---

## Step 5: 複数フィルタを順序通り実行する（GREEN）

---

## Step 6: 特定のActionにだけ適用したいというテストを書く（RED）

### テスト例

```ruby
def test_before_action_only_applies_to_specific_action
  controller = UsersController.new(env_for("/users"))

  calls = []

  UsersController.before_action(only: [:index]) do
    calls << "before"
  end

  controller.dispatch(:index)
  controller.dispatch(:show)

  assert_equal ["before"], calls
end
```

👉 RED

---

## Step 7: only オプションを実装する（GREEN）

---

## Step 8: except オプションをテストで定義する（RED）

```ruby
UsersController.before_action(except: [:show]) do
  ...
end
```

👉 RED → GREEN

---

## Step 9: before_actionで処理を中断したいというテストを書く（RED）

### テスト例

```ruby
def test_before_action_can_halt_execution
  controller = UsersController.new(env_for("/users"))

  UsersController.before_action do
    controller.render_text "blocked"
  end

  response = controller.dispatch(:index)

  assert_equal ["blocked"], response[2]
end
```

👉 RED

---

## Step 10: フィルタでAction実行を止められるようにする（GREEN）

### やること

* render / redirect が呼ばれたら後続を止める

---

## Step 11: before_actionをメソッド参照にしたいというテストを書く（RED）

### テスト例

```ruby
UsersController.before_action :authenticate
```

👉 RED

---

## Step 12: シンボル指定を実装する（GREEN）

---

## Step 13: Controller継承時の挙動をテストで固定する（RED）

### テスト例

```ruby
class AdminController < UsersController
end
```

* before_actionが引き継がれるか？

👉 RED

---

## Step 14: 継承時のフィルタ動作を実装（GREEN）

---

## Step 15: REFACTOR — フィルタチェーンを整理する

ここまで来ると構造が見えてきます：

* before_actionのリスト
* 実行順序
* 条件分岐（only/except）
* 中断制御

### 課題

責務を整理してください：

* `run_before_actions`
* `applicable_filters_for(action)`
* `halted?`

---

# 発展課題

---

## 課題1: after_action を導入する

* Actionの後に実行される処理

---

## 課題2: around_action を考える

* 前後をラップする処理

---

## 課題3: Rack Middlewareとの違いを説明する

### 問い

* ControllerフィルタとRack Middlewareの違いは何か
* どの層で使うべきか

---

# 提出物

---

## 1. テストコード

* before_action
* 複数実行
* only / except
* 中断
* メソッド指定
* 継承

---

## 2. 実装コード

* ControllerBase
* フィルタ処理

---

## 3. 設計メモ

以下を説明：

* before_actionは何を解決するか
* なぜControllerに入れるのか
* Middlewareとの違い
* 処理の流れはどう設計したか

---

# レビュー観点

* TDDを守っているか
* フィルタの責務が明確か
* 実行順序が正しいか
* 中断制御が適切か
* 過剰設計でないか

---

# このフェーズの本質

このフェーズで得るべき理解は：

> フレームワークは「処理の流れを制御する仕組み」である

---

# 次フェーズへの接続

ここまで来ると、次が自然に見えます：

* DBを扱いたい
* モデルを分離したい

👉 Phase 5: ORM / Model 層へ

---

# 🔥 このフェーズの価値（かなり重要）

ここが入ると一気に変わります：

- Railsの before_action の理解が本質レベルになる
- Middlewareとの違いが説明できるようになる
- 「処理の流れを設計する力」がつく

---

# カリキュラム全体としての完成度

ここまで来ると受講者は：

- フレームワークを「使う人」ではなく
- フレームワークを「説明できる人」

になります

---

[← 前へ: Phase 4.6](./phase-4-6.md) | [目次](./README.md#カリキュラムテキスト) | [次へ: Phase 5.1 →](./phase-5-1.md)
