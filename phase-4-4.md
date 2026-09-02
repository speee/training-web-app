# Phase 4.4: render / redirect をTDDで実装する

[← 前へ: Phase 4.3](./phase-4-3.md) | [目次](./README.md#カリキュラムテキスト) | [次へ: Phase 4.5 →](./phase-4-5.md)

## 概要

実行前に[共通セットアップと各Phaseの確認手順](./SETUP.md#4-各phaseの実行と引き継ぎ)を確認してください。演習コードは`work/`で前のPhaseから引き継ぎます。

このフェーズでは、Phase 4.3で導入した Controller / Action 構造の上に、**render / redirect**を TDD（テスト駆動開発）で導入します。

Phase 4.3までで、Router から Controller の Action を呼び出せるようになりました。  
しかし現状では、多くの Action が次のように直接 Rack レスポンスを返しているはずです。

```ruby
[200, { "content-type" => "text/html" }, ["<h1>Hello</h1>"]]
````

このままでは、

* Action のたびに同じ構造を書く必要がある
* HTTPレスポンスの詳細がアプリケーションコードに漏れ出る
* 「何を返したいか」より「どう返すか」に意識が向いてしまう
* redirect のような表現が不自然になる

という問題が発生します。

このフェーズでは、それを解決するために、

> Action からは「意味」でレスポンスを表現し、
> Controller 側で HTTP レスポンスを組み立てる

という構造を導入します。

なお、このフェーズでも必ず
**RED → GREEN → REFACTOR**
の流れで進めてください。

---

## このフェーズの目的

以下を説明できる状態になること：

* render は何を抽象化しているのか
* redirect は HTTP 的に何をしているのか
* なぜ Action から Rack 配列を直接返さない方がよいのか
* ControllerBase にレスポンス生成の責務を持たせる意味

---

## 到達目標

* Controller から `render_text` を呼べる
* Controller から `render_html` を呼べる
* Controller から `redirect_to` を呼べる
* Action が Rack レスポンス配列を直接返さなくても動く
* 二重 render / redirect を防げる
* TDD でレスポンス生成の仕様を積み上げられる

---

## 前提

* [Phase 4.3](./phase-4-3.md)（Controller / Action のTDD実装）完了
* Minitest を使えること

---

## 重要ルール

このフェーズでは、以下を必ず守ってください。

### 1. 実装より先にテストを書く

### 2. 失敗することを確認する（RED）

### 3. 最小の実装で通す（GREEN）

### 4. テストを壊さずに整理する（REFACTOR）

---

## このフェーズで目指す最終形

最終的には、以下のような Action を書ける状態を目指します。

```ruby
class UsersController < ControllerBase
  def index
    render_text "Users Index"
  end

  def show
    render_html "<h1>User Detail</h1>"
  end

  def create
    redirect_to "/users"
  end
end
```

ただし、最初からここを目指して一気に実装してはいけません。
必ず小さな振る舞いごとにテストを書いて進めてください。

---

## 演習課題

---

## Step 1: Action が `render_text` を呼べるという失敗テストを書く（RED）

まずは最小の render として、plain text を返す `render_text` を導入します。

### テスト例

```ruby
def test_action_can_render_text
  router = Router.new
  router.get "/hello", to: "pages#hello"

  status, headers, body = router.call(env_for("/hello"))

  assert_equal 200, status
  assert_equal "text/plain", headers["content-type"]
  assert_equal ["Hello"], body
end
```

```ruby
class PagesController < ControllerBase
  def hello
    render_text "Hello"
  end
end
```

### 状態

* `render_text` がまだ存在しない
* 失敗してよい

👉 これが RED

---

## Step 2: 最小の実装で `render_text` を通す（GREEN）

### やること

* `ControllerBase` に `render_text` を追加する
* `text/plain` を返す
* ステータス 200 を返す
* ボディに文字列を入れる

### 考えるべきこと

* Action の戻り値として返すのか
* Controller 内部にレスポンス状態を持たせるのか

### 注意

最初は不格好でも構いません。
まずはテストを通すことを優先してください。

---

## Step 3: Action が値を直接返さなくても動くようにする（RED）

`render_text` が導入できたら、次は Action の責務を明確にします。

### テスト例

```ruby
def test_action_does_not_need_to_return_rack_response_directly
  controller = PagesController.new(env_for("/hello"))
  response = controller.dispatch(:hello)

  assert_equal 200, response[0]
  assert_equal "text/plain", response[1]["content-type"]
  assert_equal ["Hello"], response[2]
end
```

```ruby
class PagesController < ControllerBase
  def hello
    render_text "Hello"
    nil
  end
end
```

### 課題

* `dispatch` のような経路が必要か考える
* Action 実行後にレスポンスを組み立てる場所を定める

### 状態

* まだ Action 実行とレスポンス生成の責務が整理されていないはず

👉 RED

---

## Step 4: Action 実行後にレスポンスを取り出せるようにする（GREEN）

### やること

* `dispatch(action_name)` のような仕組みを導入する
* Action 実行後に Controller の内部状態から Rack レスポンスを生成する

### 目標

Action の中では

```ruby
render_text "Hello"
```

だけ書けばよく、Rack 配列は Controller 側が責任を持つようにすること

---

## Step 5: `render_html` を追加する失敗テストを書く（RED）

次に HTML を返す render を導入します。

### テスト例

```ruby
def test_action_can_render_html
  router = Router.new
  router.get "/html", to: "pages#html"

  status, headers, body = router.call(env_for("/html"))

  assert_equal 200, status
  assert_equal "text/html", headers["content-type"]
  assert_equal ["<h1>Hello</h1>"], body
end
```

```ruby
class PagesController < ControllerBase
  def html
    render_html "<h1>Hello</h1>"
  end
end
```

### 状態

* `render_html` がまだないので失敗するはず

👉 RED

---

## Step 6: `render_html` を最小実装する（GREEN）

### やること

* `render_html` を追加する
* `content-type` を `text/html` にする

### 考えるべきこと

* `render_text` と共通化できる部分はどこか
* 内部的に共通の `render` にまとめるべきか

### 注意

まだ大きな抽象化は不要です。
重複が見えてから整理してください。

---

## Step 7: ステータスコードを指定したいという失敗テストを書く（RED）

render を使うと、200以外のレスポンスも返したくなります。

### テスト例

```ruby
def test_render_text_can_accept_status
  router = Router.new
  router.get "/not_found", to: "pages#not_found"

  status, headers, body = router.call(env_for("/not_found"))

  assert_equal 404, status
  assert_equal "text/plain", headers["content-type"]
  assert_equal ["Not Found"], body
end
```

```ruby
class PagesController < ControllerBase
  def not_found
    render_text "Not Found", status: 404
  end
end
```

### 状態

* `status:` オプションがまだないなら失敗するはず

👉 RED

---

## Step 8: render にステータス指定を追加する（GREEN）

### やること

* `status:` を受け取れるようにする
* 指定がなければ 200
* 指定があればその値を使う

### ここでの学び

`render` は単なる文字列返却ではなく、
HTTP レスポンスの組み立てを抽象化していること

---

## Step 9: `redirect_to` の失敗テストを書く（RED）

次に redirect を導入します。

### テスト例

```ruby
def test_action_can_redirect
  router = Router.new
  router.post "/users", to: "users#create"

  status, headers, body = router.call(env_for("/users", method: "POST"))

  assert_equal 302, status
  assert_equal "/users", headers["location"]
  assert_equal [], body
end
```

```ruby
class UsersController < ControllerBase
  def create
    redirect_to "/users"
  end
end
```

### 状態

* `redirect_to` がまだ存在しないはず

👉 RED

---

## Step 10: `redirect_to` を最小実装する（GREEN）

### やること

* `redirect_to(path)` を追加する
* ステータス 302
* `location` ヘッダ
* ボディは空配列でもよい

### 考察

* redirect は render と何が違うか
* redirect は body を返すのではなく「移動先を通知する」こと

---

## Step 11: `redirect_to` のステータスを変えたいという失敗テストを書く（RED）

実務では 302 以外のリダイレクトもあります。

### テスト例

```ruby
def test_redirect_to_can_accept_status
  controller = UsersController.new(env_for("/users"))
  response = controller.dispatch(:moved)

  assert_equal 301, response[0]
  assert_equal "/new_users", response[1]["location"]
end
```

```ruby
class UsersController < ControllerBase
  def moved
    redirect_to "/new_users", status: 301
  end
end
```

### 状態

* `status:` オプションがまだなければ失敗する

👉 RED

---

## Step 12: `redirect_to` にステータス指定を追加する（GREEN）

### やること

* `status:` を受け取れるようにする
* デフォルトは 302
* 指定されたらその値を使う

---

## Step 13: 二重 render を防ぐ失敗テストを書く（RED）

1つの Action で複数回 render / redirect されると、レスポンスが不定になります。

### テスト例

```ruby
def test_raises_error_when_render_called_twice
  controller = DoubleRenderController.new(env_for("/double"))

  assert_raises RuntimeError do
    controller.dispatch(:index)
  end
end
```

```ruby
class DoubleRenderController < ControllerBase
  def index
    render_text "A"
    render_text "B"
  end
end
```

### 状態

* まだ二重 render を防いでいなければ失敗しないはず

👉 RED

---

## Step 14: 二重 render / redirect を防ぐ（GREEN）

### やること

* render または redirect 済みかどうかを管理する
* 2回目以降は例外を発生させる

### 課題

* どのタイミングでフラグを立てるか
* render と redirect の両方に共通の判定が必要か

---

## Step 15: Action が何も render しない場合を先にテストで決める（RED）

何も render / redirect しない Action をどう扱うかを、テストで先に決めてください。

### 候補

* エラーにする
* 空レスポンスにする
* 暫定で 200 / empty body にする

### テスト例（エラーにする場合）

```ruby
def test_raises_error_when_nothing_rendered
  controller = EmptyController.new(env_for("/empty"))

  assert_raises RuntimeError do
    controller.dispatch(:index)
  end
end
```

```ruby
class EmptyController < ControllerBase
  def index
  end
end
```

### 注意

ここは「正解が1つ」ではありません。**どの振る舞いにするかを先に決め、テストで固定すること**が重要です。

---

## Step 16: 選んだ仕様を最小実装する（GREEN）

### やること

* Step 15 で決めた仕様に従って実装する

### 課題

* なぜその仕様にしたのか説明できること

---

## Step 17: REFACTOR — render / redirect の共通化を行う

ここまで進むと、内部で次のような重複が見えてくるはずです。

* ステータスの設定
* ヘッダの設定
* body の設定
* 二重 render の判定

### 課題

重複を減らし、責務を整理してください。

### 例

* `response_built?`
* `ensure_not_rendered!`
* `set_response`
* `build_response`

### 目標

* Action は「何を返したいか」に集中できる
* ControllerBase は「どう HTTP レスポンスを組み立てるか」を担当する

---

## 発展課題

### 課題1: `render_json` を追加する

以下のような使い方をテストから追加する：

```ruby
render_json({ name: "Alice" })
```

### 期待する挙動

* `content-type: application/json`
* body は JSON 文字列

---

### 課題2: 任意のヘッダを render に渡せるようにする

以下のような使い方をテストから追加する：

```ruby
render_text "ok", headers: { "x-test" => "true" }
```

---

### 課題3: redirect の body を持たせるか考察する

* 空でもよいか
* 最低限のメッセージを返すべきか
* ブラウザ以外のクライアントではどう考えるか

---

## 提出物

### 1. テストコード

最低限、以下を含むこと：

* `render_text` が動く
* `render_html` が動く
* render に `status:` を渡せる
* `redirect_to` が動く
* redirect に `status:` を渡せる
* 二重 render / redirect が防がれる
* 何も render しない場合の仕様がテストで固定されている

### 2. 実装コード

* `ControllerBase`
* サンプル Controller

### 3. 設計メモ

以下について説明してください：

* render は何を抽象化しているか
* redirect は HTTP 的に何をしているか
* Action から Rack 配列を直接返さない利点は何か
* 何も render しない場合の仕様をどう決めたか
* テストによって設計がどう変わったか

---

## レビュー観点

* RED → GREEN → REFACTOR を守れているか
* テストが振る舞いの仕様として機能しているか
* ControllerBase に責務が適切に集約されているか
* Action から HTTP の詳細が隠蔽されているか
* 二重 render / redirect を正しく防げているか
* 過剰設計になっていないか

---

## AI活用

### OK

* HTTPステータスコードの意味の確認
* redirect のHTTP仕様の確認
* テスト粒度の相談
* 責務分離の壁打ち

### NG

* 実装の生成
* 完成コードの出力
* 解答の丸写し

---

## よくある失敗

### 1. 最初から汎用的な render を作ろうとする

→ まずは `render_text` 1つから始めること

### 2. Action が Rack レスポンス配列を返し続けてしまう

→ render 導入の意味が薄れる

### 3. redirect を単なる文字列返却だと考える

→ `location` ヘッダとステータスコードが本質

### 4. 二重 render の問題を後回しにする

→ フレームワークとして重要な責務

### 5. 「何も render しない場合」の仕様を曖昧にする

→ テストで固定すること

---

## このフェーズの本質

このフェーズで得るべき理解は、

> フレームワークの仕事は、
> HTTP の詳細を隠しながらも、HTTP との対応関係を失わせないこと

ということです。

render / redirect は単なる便利メソッドではありません。
それは、Action から見た「意味」と、HTTP レスポンスという「具体」の橋渡しです。

---

## 次フェーズへの接続

ここまで来ると次の問題が自然に見えてきます。

* HTML を Action の中に文字列で書くのがつらい
* 表示とロジックを分離したい
* データをビューに渡したい

次のフェーズでは、これを解決するために

> View / Template

を TDD で導入します。

---

## 最後に

このフェーズでは、完成形に近い便利メソッドを作ることが目的ではありません。

大切なのは、

* どの振る舞いを先に固定したか
* どこで痛みを感じたか
* どの責務を ControllerBase に寄せたか

を、自分の手で設計しながら理解することです。

---

[← 前へ: Phase 4.3](./phase-4-3.md) | [目次](./README.md#カリキュラムテキスト) | [次へ: Phase 4.5 →](./phase-4-5.md)
