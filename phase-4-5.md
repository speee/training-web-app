# Phase 4.5: View / Template をTDDで導入する

[← 前へ: Phase 4.4](./phase-4-4.md) | [目次](./README.md#カリキュラムテキスト) | [次へ: Phase 4.6 →](./phase-4-6.md)

## 概要

実行前に[共通セットアップと各Phaseの確認手順](./SETUP.md#4-各phaseの実行と引き継ぎ)を確認してください。演習コードは`work/`で前のPhaseから引き継ぎます。

このフェーズでは、Phase 4.4で導入した `render` / `redirect` の上に、**View / Template**をTDD（テスト駆動開発）で導入します。

Phase 4.4までで、Controller の Action は Rack レスポンス配列を直接返さず、

- `render_text`
- `render_html`
- `redirect_to`

のような表現でレスポンスを返せるようになりました。

しかし現状では、HTML を返す場合でも多くの Action は次のように、
HTML文字列を直接書いているはずです。

```ruby
def index
  render_html "<h1>Users</h1><ul><li>Alice</li></ul>"
end
````

このままでは、

* HTMLが長くなると読みづらい
* 画面の変更がつらい
* ロジックと表示が混ざる
* 同じHTML構造が繰り返される

という問題が発生します。

このフェーズでは、それを解決するために、

> 表示はテンプレートに任せ、
> Controller は表示に必要なデータを準備する

という構造を導入します。

なお、このフェーズでも必ず
**RED → GREEN → REFACTOR**
の流れで進めてください。

---

## このフェーズの目的

以下を説明できる状態になること：

* View とは何か
* Template とは何か
* なぜ HTML を Controller に書かない方がよいのか
* なぜ Controller のインスタンス変数を View から参照できるのか
* テンプレートエンジンが何をしているのか

---

## 到達目標

* HTMLを外部ファイルに分離できる
* ERBテンプレートを評価できる
* Controller から `render_view` を使える
* Controller のインスタンス変数を View から参照できる
* レイアウトの必要性が見えるところまで到達する
* TDD で View / Template の仕様を積み上げられる

---

## 前提

* [Phase 4.4](./phase-4-4.md)（render / redirect のTDD実装）完了
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

最終的には、以下のようなコードを書ける状態を目指します。

```ruby
class UsersController < ControllerBase
  def index
    @users = ["Alice", "Bob"]
    render_view "users/index"
  end
end
```

```erb
<!-- views/users/index.erb -->
<h1>Users</h1>
<ul>
  <% @users.each do |user| %>
    <li><%= h(user) %></li>
  <% end %>
</ul>
```

ただし、最初から完成形を一気に実装してはいけません。
必ず小さな失敗テストから進めてください。

---

## 演習課題

---

## Step 1: HTML文字列直書きのつらさを先に確認する

まず、現在の `render_html` を使った Action を見直してください。

### 課題

以下のような Action をあえて書いてみる：

```ruby
class UsersController < ControllerBase
  def index
    render_html "<h1>Users</h1><ul><li>Alice</li><li>Bob</li></ul>"
  end
end
```

### 観察ポイント

* HTMLが長くなるとどう感じるか
* 画面の変更はしやすいか
* ロジックと表示が混ざっていないか

### 気づき

> 「HTMLはコードの中に直接書くべきではない」

この気づきを持った上で、以下のTDDに進んでください。

---

## Step 2: HTMLファイルを読み込んで返したいという失敗テストを書く（RED）

まずはテンプレートエンジンを使わず、**静的なHTMLファイルを読み込んで返す**ところから始めます。

### テスト例

```ruby
def test_action_can_render_html_file
  write_view("pages/home.html", "<h1>Home</h1>")

  router = Router.new
  router.get "/", to: "pages#home"

  status, headers, body = router.call(env_for("/"))

  assert_equal 200, status
  assert_equal "text/html", headers["content-type"]
  assert_equal ["<h1>Home</h1>"], body
end
```

```ruby
class PagesController < ControllerBase
  def home
    render_file "pages/home.html"
  end
end
```

### 状態

* `render_file` がまだ存在しない
* ビュー読み込みの仕組みもまだない

👉 これが RED

---

## Step 3: 最小実装で静的HTMLファイルを返す（GREEN）

### やること

* `render_file` を追加する
* ファイルを読み込む
* `render_html` 相当のレスポンスを返す

### 注意

* まだ ERB は使わない
* まずは「HTMLをコードの外に出す」だけでよい

---

## Step 4: `.erb` ファイルを評価したいという失敗テストを書く（RED）

次に、ただのHTMLではなくテンプレートとして評価したくなります。

### テスト例

```ruby
def test_action_can_render_erb_template
  write_view("pages/hello.erb", "<h1>Hello <%= 'World' %></h1>")

  router = Router.new
  router.get "/hello", to: "pages#hello"

  status, headers, body = router.call(env_for("/hello"))

  assert_equal 200, status
  assert_equal "text/html", headers["content-type"]
  assert_equal ["<h1>Hello World</h1>"], body
end
```

```ruby
class PagesController < ControllerBase
  def hello
    render_view "pages/hello"
  end
end
```

### 状態

* `render_view` がまだない
* ERB評価もまだできないはず

👉 RED

---

## Step 5: ERBを最小導入する（GREEN）

### やること

* Ruby標準ライブラリの `ERB` を使う
* `views/pages/hello.erb` のようなファイルを読み込む
* ERBとして評価してHTML文字列を生成する
* `text/html` でレスポンスを返す

### 必須: ERB出力とXSS

Ruby標準のERBは`<%= ... %>`の値を自動でHTMLエスケープしません。リクエストやDBから来た値をそのまま埋め込むと、タグやスクリプトとして実行されるXSSにつながります。保存済みの値も信頼せず、出力時に処理してください。

以後の例では、HTML本文のテキスト用に`h(value)`というViewヘルパを使います。`ERB::Util.html_escape`などを調べて、テストからこのヘルパを用意してください。HTML全体ではなく、埋め込む値をエスケープします。テンプレートのコードとファイル名は開発者が管理し、ユーザー入力をERBとして評価しません。

- [ ] `<script>alert(1)</script>`という値が`&lt;script&gt;alert(1)&lt;/script&gt;`として出力され、ブラウザで実行されず文字列として見える
- [ ] `&`・`<`・`>`・引用符を含む値も表示でき、DBへ保存して再表示する経路でもエスケープされる（DB経由の確認はPhase 5以降へ引き継ぐ）
- [ ] フォームの属性値へ埋め込む場合は引用符で囲み、引用符を含む入力で属性を脱出できないことを確認する

HTMLエスケープだけでJavaScript・CSS・URLのすべてを安全にできるわけではありません。この演習では入力をscript・style・イベントハンドラへ埋め込まず、入力からリンク先を作る場合はURLスキームなども制限します。参照: [OWASPのXSS対策](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html)。

### 考えるべきこと

* テンプレートファイルの探索ルール
* `.erb` の拡張子をどこで付けるか
* `render_file` と `render_view` の関係

---

## Step 6: Controller のインスタンス変数を View から参照したいという失敗テストを書く（RED）

テンプレートを導入すると、次に必要になるのはデータの受け渡しです。

### テスト例

```ruby
def test_view_can_access_controller_instance_variables
  write_view("users/index.erb", "<h1><%= h(@title) %></h1>")

  router = Router.new
  router.get "/users", to: "users#index"

  status, _, body = router.call(env_for("/users"))

  assert_equal ["<h1>Users</h1>"], body
end
```

```ruby
class UsersController < ControllerBase
  def index
    @title = "Users"
    render_view "users/index"
  end
end
```

### 状態

* View の評価スコープが適切でなければ失敗するはず

👉 RED

---

## Step 7: Controller のスコープでテンプレートを評価する（GREEN）

### やること

* View を Controller の文脈で評価できるようにする
* `@title` のようなインスタンス変数が使えるようにする

### ヒント

* `binding` の役割を理解する

### 課題

以下を説明できるようにすること：

* なぜ View から `@title` を見られるのか
* その値はどこに保存されているのか

---

## Step 8: 繰り返し表示をしたいという失敗テストを書く（RED）

View の強みは、データを受け取って構造を組み立てられることです。

### テスト例

```ruby
def test_view_can_render_collection_from_instance_variable
  write_view("users/index.erb", <<~ERB)
    <ul>
      <% @users.each do |user| %>
        <li><%= h(user) %></li>
      <% end %>
    </ul>
  ERB

  router = Router.new
  router.get "/users", to: "users#index"

  status, _, body = router.call(env_for("/users"))

  assert_equal ["<ul>\n  <li>Alice</li>\n  <li>Bob</li>\n</ul>\n"], body
end
```

```ruby
class UsersController < ControllerBase
  def index
    @users = ["Alice", "Bob"]
    render_view "users/index"
  end
end
```

### 状態

* ERBが正しく評価できていれば通る
* 評価文脈や改行が不適切なら失敗するかもしれない

👉 RED

---

## Step 9: テンプレート評価の振る舞いを安定させる（GREEN）

### やること

* ERBの評価結果が期待通りになるように調整する
* テストを通す最小修正を行う

### 注意

* ここでは見た目の整形ではなく、テンプレートが評価されることが主目的
* 改行差分は必要に応じてテストで吸収してもよいが、なぜそうしたか説明できること

---

## Step 10: `render_view` のパス解決を先にテストで固定する（RED）

今後Viewが増えると、テンプレートパスの解決ルールが重要になります。

### テスト例

```ruby
def test_render_view_resolves_template_path_under_views_directory
  write_view("users/show.erb", "<h1>User Detail</h1>")

  controller = UsersController.new(env_for("/users/1"))
  response = controller.dispatch(:show)

  assert_equal ["<h1>User Detail</h1>"], response[2]
end
```

```ruby
class UsersController < ControllerBase
  def show
    render_view "users/show"
  end
end
```

### 課題

* `render_view "users/show"` がどのファイルを参照するか
* なぜルールが必要なのか

👉 RED

---

## Step 11: パス解決ルールを最小実装する（GREEN）

### やること

* `views/users/show.erb` のようなルールを実装する
* そのルールを1箇所に閉じ込める

### 目標

* Controller はファイルシステムの詳細を知らずに済むこと

---

## Step 12: 存在しないテンプレートの振る舞いを先にテストで決める（RED）

テンプレートが存在しない場合の扱いを先に決めます。

### 候補

* 例外にする
* 500相当のエラーにする
* 専用のエラークラスを投げる

### テスト例（例外にする場合）

```ruby
def test_raises_error_when_template_is_missing
  controller = UsersController.new(env_for("/users"))

  assert_raises RuntimeError do
    controller.dispatch(:index)
  end
end
```

```ruby
class UsersController < ControllerBase
  def index
    render_view "users/missing"
  end
end
```

### 注意

ここも正解は1つではありません。**どの振る舞いにするかを先に決め、テストで固定すること**が重要です。

---

## Step 13: 選んだ仕様を最小実装する（GREEN）

### やること

* Step 12で決めた仕様に従って実装する
* なぜその仕様を選んだか説明できるようにする

---

## Step 14: layout が欲しくなる失敗を観察する

ここではまだ layout を実装しません。
ただし、必要性が見えるところまでは進めます。

### 課題

複数画面を作ってみてください。

* `pages/home`
* `users/index`
* `users/show`

そのうえで、共通して書いているHTMLがないか観察してください。

### 例

* `<html>`
* `<body>`
* 共通ヘッダ
* 共通フッタ

### 気づき

> 「各Viewの外側に共通枠を持たせたい」

この気づきが、次の抽象化の種になります。

---

## Step 15: REFACTOR — View描画責務を整理する

ここまで進むと、次のような責務が見えてきます。

* テンプレートパスを解決する
* ファイルを読む
* ERBで評価する
* HTMLとして render する

### 課題

責務を整理し、必要ならメソッドを分けてください。

### 例

* `template_path_for`
* `render_template`
* `evaluate_template`

### 目標

* `render_view` は Controller にとって読みやすい入口であること
* View描画の詳細は ControllerBase の内部に閉じ込められていること

---

## 発展課題

### 課題1: `locals` を使いたいというテストを書く

以下のような使い方を、インスタンス変数とは別にテストで導入する：

```ruby
render_view "users/show", locals: { user_name: "Alice" }
```

### 問い

* `@user_name` と `user_name` の違いは何か
* どちらが設計として分かりやすいか

---

### 課題2: レイアウトを導入する

以下のような構造をテストから導入する：

```erb
<!-- views/layouts/application.erb -->
<html>
  <body>
    <%= yield %>
  </body>
</html>
```

### 問い

* レイアウトはどこで適用するべきか
* すべてのViewに適用するか、選べるようにするか

---

### 課題3: Viewヘルパが欲しくなる状況を観察する

* 同じ表示ロジックがViewで繰り返されていないか
* どこまでをViewに書き、どこからをHelperに逃がすべきか

---

## 提出物

### 1. テストコード

最低限、以下を含むこと：

* HTMLファイルを読み込んで返せる
* ERBテンプレートを評価できる
* Controllerのインスタンス変数をViewから参照できる
* HTMLに埋め込む値がエスケープされ、入力をタグとして実行させない
* 配列を使った繰り返し表示ができる
* `render_view` のテンプレートパス解決ができる
* 存在しないテンプレートの振る舞いがテストで固定されている

### 2. 実装コード

* `ControllerBase`
* 必要ならView描画を担う補助メソッド
* サンプルController
* サンプルViewファイル

### 3. 設計メモ

以下について説明してください：

* なぜ HTML を Controller に直接書かない方がよいのか
* なぜ View から Controller のインスタンス変数を参照できるのか
* `render_view` は何を抽象化しているか
* テンプレートが存在しない場合の仕様をどう決めたか
* layout が欲しくなる理由は何か

---

## レビュー観点

* RED → GREEN → REFACTOR を守れているか
* テストが振る舞いの仕様として機能しているか
* HTML生成が Controller から分離されているか
* ERBと評価スコープの関係を理解しているか
* テンプレートパス解決の責務が整理されているか
* 過剰な抽象化をしていないか

---

## AI活用

### OK

* ERB の構文確認
* `binding` の概念理解
* テスト粒度の相談
* 責務分離の壁打ち

### NG

* 実装の生成
* 完成コードの出力
* 解答の丸写し

---

## よくある失敗

### 1. 最初からレイアウトまで一気に作る

→ まずは「1つのテンプレートを評価する」ことから始める

### 2. HTMLファイル読み込みとERB評価を同時にやる

→ 最初は静的ファイル、その次にERB、の順に分ける

### 3. Viewにアプリケーションロジックを書きすぎる

→ Viewは表示、Controllerはデータ準備

### 4. `binding` の意味を理解せずに使う

→ なぜインスタンス変数が見えるのか説明できること

### 5. テンプレート探索ルールを曖昧にする

→ テストで仕様を先に固定すること

---

## このフェーズの本質

このフェーズで得るべき理解は、

> フレームワークの仕事は、
> 「表示」を「処理」から分離しつつ、必要なデータだけを橋渡しすること

ということです。

View / Template の導入は、単にHTMLを外に出すことではありません。
それは、

* 表示の変更をしやすくし
* Controller の責務を明確にし
* Webアプリケーションを継続的に改善可能な構造にする

ための重要な抽象化です。

---

## 次フェーズへの接続

ここまでで、以下が揃ってきました。

* Routing
* Controller / Action
* render / redirect
* View / Template

次に自然に見えてくる問題は、

* `params` の扱いが曖昧
* `query parameter` と `path parameter` の関係が整理されていない
* request の情報をどこまで Controller に見せるかが不明確

次のフェーズでは、これを解決するために

> Request / Params の整理

を TDD で導入します。

---

## 最後に

このフェーズでは、見た目を整えることよりも、

* どの振る舞いを先にテストで固定したか
* どこで責務の分離が必要だと気づいたか
* なぜテンプレートという仕組みが必要なのか

を理解することが重要です。

View の導入により、アプリケーションはさらに **「長く開発できる構造」** に近づいていきます。

---

[← 前へ: Phase 4.4](./phase-4-4.md) | [目次](./README.md#カリキュラムテキスト) | [次へ: Phase 4.6 →](./phase-4-6.md)
