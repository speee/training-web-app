# Phase 4.6: Request / Params をTDDで整理する

[← 前へ: Phase 4.5](./phase-4-5.md) | [目次](./README.md#カリキュラムテキスト) | [次へ: Phase 4.7 →](./phase-4-7.md)

## 概要

実行前に[共通セットアップと各Phaseの確認手順](./SETUP.md#4-各phaseの実行と引き継ぎ)を確認してください。演習コードは`work/`で前のPhaseから引き継ぎます。

このフェーズでは、Phase 4.5までで構築してきた自作Webアプリケーションフレームワークに対して、**Request / Params の扱いを TDD（テスト駆動開発）で整理**します。

ここまでで、以下の要素はすでに揃っているはずです。

- Routing
- Controller / Action
- render / redirect
- View / Template

しかし現状では、Controller の中で扱う入力情報がまだ曖昧なはずです。

例えば：

- query parameter はどこから取るのか
- path parameter はどこにあるのか
- form parameter はどう扱うのか
- `params` は何を含むのか
- `request` はどこまで Controller に見せるべきか

このフェーズでは、それらを整理し、

> Action から request / params を自然かつ一貫した形で扱えるようにする

ことを目指します。

なお、このフェーズでも必ず  
**RED → GREEN → REFACTOR**  
の流れで進めてください。

---

## このフェーズの目的

以下を説明できる状態になること：

- Request とは何か
- Params とは何か
- query parameter / path parameter / form parameter の違い
- なぜそれらを Controller から統一的に扱いたくなるのか
- なぜ `request` と `params` を分けるのか

---

## 到達目標

- Controller から `request` を参照できる
- Controller から `params` を参照できる
- query parameter を `params` で扱える
- path parameter を `params` で扱える
- form parameter を `params` で扱える
- `request` と `params` の責務の違いを説明できる
- TDD で request / params の仕様を積み上げられる

---

## 前提

- [Phase 4.5](./phase-4-5.md)（View / Template のTDD実装）完了
- Minitest を使えること

---

## 重要ルール

このフェーズでは、以下を必ず守ってください。

### 1. 実装より先にテストを書く
### 2. 失敗することを確認する（RED）
### 3. 最小の実装で通す（GREEN）
### 4. テストを壊さずに整理する（REFACTOR）

---

## このフェーズで目指す最終形

最終的には、以下のようなコードを書ける状態を目指します。

```ruby
class UsersController < ControllerBase
  def show
    id = params["id"]
    page = params["page"]
    method = request.request_method

    render_text "id=#{id}, page=#{page}, method=#{method}"
  end
end
````

ただし、最初からここを一気に作ってはいけません。
必ず小さな失敗テストから順に進めてください。

---

## 演習課題

---

## Step 1: Controller から request を参照したいという失敗テストを書く（RED）

まずは、Controller の Action から request オブジェクトを扱いたい、という要件を固定します。

### テスト例

```ruby
def test_controller_can_access_request
  router = Router.new
  router.get "/info", to: "pages#info"

  status, _, body = router.call(env_for("/info"))

  assert_equal 200, status
  assert_equal ["GET"], body
end
```

```ruby
class PagesController < ControllerBase
  def info
    render_text request.request_method
  end
end
```

### 状態

* `request` がまだ存在しないなら失敗するはず

👉 これが RED

---

## Step 2: 最小実装で request を参照できるようにする（GREEN）

### やること

* ControllerBase に `request` を持たせる
* `Rack::Request` あるいは独自の Request ラッパーを通じて扱えるようにする

### 考えるべきこと

* まずは `Rack::Request` をそのまま持つか
* 後で独自 Request クラスに包むか

### 注意

最初から独自実装に寄せすぎなくてよいです。
まずは Controller から request が見えることを優先してください。

---

## Step 3: query parameter を params で参照したいという失敗テストを書く（RED）

次に、URL のクエリ文字列を Action から扱いたくなります。

### テスト例

```ruby
def test_controller_can_access_query_params
  router = Router.new
  router.get "/search", to: "pages#search"

  status, _, body = router.call(env_for("/search?keyword=ruby"))

  assert_equal 200, status
  assert_equal ["ruby"], body
end
```

```ruby
class PagesController < ControllerBase
  def search
    render_text params["keyword"]
  end
end
```

### 状態

* `params` がまだない、または query parameter を見ていないなら失敗するはず

👉 RED

---

## Step 4: query parameter を params で返す最小実装を行う（GREEN）

### やること

* ControllerBase に `params` を追加する
* まずは query parameter だけを返せればよい

### 課題

以下を説明できるようにすること：

* `request` と `params` は何が違うか
* なぜ `request.params` をそのまま使わず、ControllerBase に `params` メソッドを置くのか

---

## Step 5: path parameter を params で参照したいという失敗テストを書く（RED）

Phase 4.2 で routing 時に path parameter を扱いました。
ここで、それを Controller 側から自然に触れるようにします。

### テスト例

```ruby
def test_controller_can_access_path_params_from_params
  router = Router.new
  router.get "/users/:id", to: "users#show"

  status, _, body = router.call(env_for("/users/42"))

  assert_equal 200, status
  assert_equal ["42"], body
end
```

```ruby
class UsersController < ControllerBase
  def show
    render_text params["id"]
  end
end
```

### 状態

* path parameter が `params` に入っていないなら失敗するはず

👉 RED

---

## Step 6: path parameter を params に統合する最小実装を行う（GREEN）

### やること

* ルータが抽出した path parameter を Controller 側に渡す
* `params` の中で query parameter と path parameter を統合して扱えるようにする

### 問い

* `params["id"]` で取れることの利便性は何か
* path と query を統合することで何が楽になるか
* 逆に、分けて持つ価値はあるか

---

## Step 7: query parameter と path parameter が両方あるケースを先にテストで固定する（RED）

統合した以上、両方が同時に存在するケースを扱う必要があります。

### テスト例

```ruby
def test_params_contains_both_path_and_query_params
  router = Router.new
  router.get "/users/:id", to: "users#show"

  status, _, body = router.call(env_for("/users/42?page=3"))

  assert_equal 200, status
  assert_equal ["id=42,page=3"], body
end
```

```ruby
class UsersController < ControllerBase
  def show
    render_text "id=#{params["id"]},page=#{params["page"]}"
  end
end
```

### 状態

* 片方しか取れていないなら失敗するはず

👉 RED

---

## Step 8: 両方の parameter を統合した params を返す（GREEN）

### やること

* query parameter と path parameter を1つのインターフェースで扱えるようにする
* 最小実装でテストを通す

### 課題

競合時の優先順位を考えてください。

例：

* path に `id=42`
* query に `id=99`

このとき `params["id"]` をどうするか

### 注意

ここも正解は1つではありません。
**どのルールにするかをテストで固定すること** が重要です。

---

## Step 9: form parameter を params で参照したいという失敗テストを書く（RED）

ここまでで GET リクエスト由来の parameter は扱えました。
次に、POST フォーム由来の parameter を扱います。

### テスト例

```ruby
def test_controller_can_access_form_params
  router = Router.new
  router.post "/users", to: "users#create"

  env = env_for("/users", method: "POST", params: { "name" => "Alice" })

  status, _, body = router.call(env)

  assert_equal 200, status
  assert_equal ["Alice"], body
end
```

```ruby
class UsersController < ControllerBase
  def create
    render_text params["name"]
  end
end
```

### 状態

* form parameter を見ていなければ失敗するはず

👉 RED

---

## Step 10: form parameter を params に含める最小実装を行う（GREEN）

### やること

* POST された form parameter を `params` に含める
* query / path / form を一貫した形で扱えるようにする

### 課題

以下を説明できるようにすること：

* query parameter と form parameter は何が違うか
* それでも `params` にまとめたくなる理由は何か

---

## Step 11: request が params 以外の情報も持つことを先にテストで固定する（RED）

`request` を導入した意味は、params 以外の情報も扱えることにあります。

### テスト例

```ruby
def test_request_exposes_path_and_method
  router = Router.new
  router.post "/inspect", to: "pages#inspect"

  status, _, body = router.call(env_for("/inspect", method: "POST"))

  assert_equal 200, status
  assert_equal ["/inspect|POST"], body
end
```

```ruby
class PagesController < ControllerBase
  def inspect
    render_text "#{request.path}|#{request.request_method}"
  end
end
```

### 状態

* `request` が単なる `params` の入れ物になっているなら不十分

👉 RED

---

## Step 12: request と params の責務を分けるよう整理する（GREEN）

### やること

* `request` はリクエスト全体を表す
* `params` は入力データをまとめたもの

という構造になるように整理する

### 目標

Controller から見たときに、

* `request` はメソッド・パス・ヘッダなどの窓口
* `params` は入力値の窓口

として理解しやすい状態にすること

---

## Step 13: params のキーアクセス仕様を先にテストで固定する（RED）

ここで、`params` の使い勝手を明確にしておきます。

### テスト候補

* キーが存在しないとき `nil` を返す
* 文字列キーで扱う
* シンボルキーは扱わない、あるいは扱う

### テスト例（文字列キーだけにする場合）

```ruby
def test_params_are_accessed_with_string_keys
  router = Router.new
  router.get "/search", to: "pages#search"

  status, _, body = router.call(env_for("/search?keyword=ruby"))

  assert_equal ["ruby|"], body
end
```

```ruby
class PagesController < ControllerBase
  def search
    render_text "#{params["keyword"]}|#{params[:keyword]}"
  end
end
```

### 注意

ここも正解は1つではありません。
**使い方のルールをテストで固定すること** が重要です。

👉 RED

---

## Step 14: 選んだ params 仕様を最小実装する（GREEN）

### やること

* Step 13 で決めた仕様に従って実装する

### 課題

* なぜそのルールを選んだのか説明できるようにすること

---

## Step 15: Action から `request.params` を直接使いたくなる状況を観察する

### 課題

Action の中で次の2つを比較してください。

```ruby
request.params["keyword"]
```

```ruby
params["keyword"]
```

### 問い

* どちらが Action にとって自然か
* なぜ ControllerBase に `params` を生やしたくなるのか
* フレームワークとしてどちらを推奨したいか

ここで気づくべきことは、

> Action から見たときに「よく使うもの」は近くに置きたくなる

という点です。

---

## Step 16: 独自 Request クラスが欲しくなる失敗を観察する

ここでは、まだ独自 Request クラスを本格導入しなくても構いません。
ただし、必要性が見えるところまでは進めます。

### 観察ポイント

* `Rack::Request` をそのまま Controller に見せ続けてよいか
* 自作フレームワーク独自の path parameter との統合はどこでやるべきか
* framework 全体で request の仕様を固定したい場面はないか

### 気づき

> 「将来的には独自の Request オブジェクトで包みたくなる」

この気づきがあれば十分です。

---

## Step 17: REFACTOR — Request / Params の責務を整理する

ここまで進むと、次の責務が見えてくるはずです。

* env から request を作る
* ルータから path parameter を渡す
* query / path / form を統合して params を作る
* Controller から扱いやすい API にする

### 課題

責務を整理し、必要ならメソッドを分けてください。

### 例

* `build_request`
* `build_params`
* `merged_params`
* `path_params`
* `request_params`

### 目標

* Controller は request / params を自然に使える
* ルータや ControllerBase に責務が偏りすぎていない
* 今後独自 Request クラスに進化させやすい形になっている

---

## 発展課題

### 課題1: params の優先順位を明示的に固定する

以下のケースをテストで定義してください。

* path parameter と query parameter が同じキーを持つ
* query parameter と form parameter が同じキーを持つ

### 問い

* どの順序で上書きするか
* なぜその順序にしたか

---

### 課題2: ネストした parameter をどう扱うか考える

例：

```ruby
user[name]=Alice
```

### 問い

* いま扱うべきか
* 後続フェーズに回すべきか
* なぜか

---

### 課題3: Header や Cookie を request に見せるテストを書く

以下のような情報を `request` から見たくなるケースを考える。

* `User-Agent`
* `Cookie`
* `Accept`

### 問い

* params と違って、なぜこれらは `request` 側なのか

---

## 提出物

### 1. テストコード

最低限、以下を含むこと：

* Controller から `request` を参照できる
* query parameter を `params` で扱える
* path parameter を `params` で扱える
* query + path parameter を同時に扱える
* form parameter を `params` で扱える
* `request` が path / method などを持つ
* params のキー仕様がテストで固定されている

### 2. 実装コード

* `ControllerBase`
* 必要に応じた Request / Params 補助コード
* サンプルController

### 3. 設計メモ

以下について説明してください：

* `request` と `params` は何が違うか
* なぜ query / path / form を `params` にまとめたのか
* parameter の優先順位をどう決めたか
* いま独自 Request クラスを本格導入しない理由
* テストによって設計がどう変わったか

---

## レビュー観点

* RED → GREEN → REFACTOR を守れているか
* テストが振る舞いの仕様として機能しているか
* request と params の責務を分けて説明できるか
* query / path / form を一貫して扱えているか
* 優先順位やキー仕様が曖昧になっていないか
* 過剰設計になっていないか

---

## AI活用

### OK

* Rack::Request の仕様確認
* query / form parameter の違いの確認
* テスト粒度の相談
* 責務分離の壁打ち

### NG

* 実装の生成
* 完成コードの出力
* 解答の丸写し

---

## よくある失敗

### 1. 最初から独自 Request クラスを作り込みすぎる

→ まずは Controller が自然に使えることを優先する

### 2. params と request の責務を混同する

→ params は入力値、request はリクエスト全体

### 3. path parameter の渡し方が場当たり的になる

→ ルータと Controller の境界で責務を整理すること

### 4. 優先順位を曖昧にする

→ 競合時のルールはテストで先に固定すること

### 5. Rack の都合をそのまま Action に漏らしすぎる

→ フレームワークとしての使いやすさを意識すること

---

## このフェーズの本質

このフェーズで得るべき理解は、

> フレームワークの仕事は、
> バラバラな入力経路を、アプリケーション開発者にとって一貫した形に整えること

ということです。

`request` と `params` の整理は地味に見えますが、
ここが曖昧だと、フレームワーク全体の使い勝手と責務分離が崩れます。

逆にここが整理されると、

* Action は自然に書ける
* 入力値の扱いが一貫する
* 後続のフォーム処理やバリデーションにもつながる

という大きな効果があります。

---

## 次フェーズへの接続

ここまでで、自作フレームワークにはかなり基本要素が揃ってきました。

* Routing
* Controller / Action
* render / redirect
* View / Template
* Request / Params

次に自然に見えてくる問題は、

* ログ出力を毎回書きたくない
* 例外処理を各所に書きたくない
* 認証や共通前処理を差し込みたい

次のフェーズでは、これを解決するために

> 共通処理（Middleware / before_action 的な仕組み）

を導入します。

---

## 最後に

このフェーズでは、派手な画面の変化は少ないかもしれません。
しかし実際には、フレームワークの使い心地を大きく左右する重要な部分を扱っています。

大切なのは、

* どの入力経路をどう統合したか
* どの責務を request に置き、どの責務を params に置いたか
* それをどのテストで先に固定したか

を理解することです。

ここを丁寧に設計できると、
自作フレームワークは一段と「人が使えるもの」に近づきます。

---

[← 前へ: Phase 4.5](./phase-4-5.md) | [目次](./README.md#カリキュラムテキスト) | [次へ: Phase 4.7 →](./phase-4-7.md)
