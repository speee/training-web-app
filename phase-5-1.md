# Phase 5.1: 生SQLのつらさをTDDで体験する

[← 前へ: Phase 4.7](./phase-4-7.md) | [目次](./README.md#カリキュラムテキスト) | [次へ: Phase 5.2 →](./phase-5-2.md)

## 概要

実行前に[共通セットアップと各Phaseの確認手順](./SETUP.md#4-各phaseの実行と引き継ぎ)を確認してください。演習コードは`work/`で前のPhaseから引き継ぎます。

このフェーズでは、Phase 4までで構築してきた自作Webアプリケーションフレームワークの上で、**Controller から直接 SQL を使ってデータを取得・表示する**実装を、TDD（テスト駆動開発）で行います。

このフェーズの目的は、まだORMを作ることではありません。

むしろ意図的に、

- Controller にSQLを書く
- DBの行データをそのまま扱う
- 取得処理と表示処理が近い状態を作る

ことで、

> 「なぜ Model / ORM が必要になるのか」

を自分の手で体験することが目的です。

なお、このフェーズでも必ず  
**RED → GREEN → REFACTOR**  
の流れで進めてください。

---

## このフェーズの目的

以下を説明できる状態になること：

- なぜ Controller にSQLを書くとつらいのか
- DBの1行をそのまま扱うと何が起きるのか
- 取得処理・変換処理・表示処理が混ざると何が困るのか
- なぜ次のフェーズで Model 層が必要になるのか

---

## 到達目標

- Controller からSQLを実行して一覧表示できる
- Controller からSQLを実行して詳細表示できる
- テストでDB依存の振る舞いを定義できる
- 実装後に「つらさ」を具体的に言語化できる

---

## 前提

- [Phase 4.7](./phase-4-7.md)（共通処理 / before_action 的仕組み）完了
- Minitest を使えること
- SQLite3 など、ローカルで扱いやすいRDBMSを使えること

---

## 重要ルール

このフェーズでは、以下を必ず守ってください。

### 1. 実装より先にテストを書く
### 2. 失敗することを確認する（RED）
### 3. 最小の実装で通す（GREEN）
### 4. テストを壊さずに整理する（REFACTOR）

---

## このフェーズで目指す最終形

最終的には、例えば次のようなコードに到達するはずです。

```ruby
class UsersController < ControllerBase
  def index
    rows = db.execute("SELECT id, name, email FROM users ORDER BY id")
    @rows = rows
    render_view "users/index"
  end

  def show
    id = params["id"]
    row = db.execute("SELECT id, name, email FROM users WHERE id = ?", [id]).first
    @row = row
    render_view "users/show"
  end
end
````

ただし、この形を最初から目指してはいけません。
必ず、小さな失敗テストから順に進めてください。

---

## このフェーズで使う題材

題材は、最小限の `users` テーブルとします。

### 例

* id
* name
* email

### 例となるレコード

* 1, Alice, [alice@example.com](mailto:alice@example.com)
* 2, Bob, [bob@example.com](mailto:bob@example.com)

---

## 必須要件: SQLインジェクションを防ぐ

このフェーズ以降、検索・登録・更新・削除の**すべての入力値をプレースホルダへバインド**します。SQL文字列への連結・埋め込みや、自前の引用符置換で入力を扱ってはいけません。これは発展課題ではなく、ControllerからModelへ移しても維持する必須要件です。

- [ ] `O'Reilly`のような引用符を含む値を、意図した1つの値として保存・検索できる
- [ ] `' OR 1=1 --`などを検索条件やIDとして渡しても、全件取得や別レコードへの操作にならない（値として扱うか、入力仕様に従って拒否する）
- [ ] 更新・削除では対象外の行と件数が変わらないこともテストで確かめる（実装するPhase 5.6で引き継ぐ）

テストには隔離した一時DBとダミーデータを使います。値のバインドと、業務上のバリデーションの役割の違いも説明してください。参照: [OWASPのSQLインジェクション対策](https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html)。

## 🔧 事前準備（SQLite3を最小ステップで動かす）

このフェーズでは SQLite3 を使ってローカルDBを用意します。

ここでは **「確実に動くこと」だけを保証し、実装は自分で考える** 形にしています。

---

## Step 0: SQLite3 が使えるか確認

```bash
sqlite3 --version
````

表示されればOKです。

もしエラーになる場合：

### macOS（Homebrew）

```bash
brew install sqlite
```

Debian/Ubuntu系での例は`sudo apt-get install sqlite3`です。ほかのOSでは対応する導入手順を調べてください。CLIとRubyのsqlite3 Gemは別です。[セットアップガイド](./SETUP.md)でそれぞれが使えることを確認します。

---

## Step 1: 基準GemfileのSQLite3を確認

演習ディレクトリの基準`Gemfile`には既に以下が含まれます（重複追加は不要）：

```ruby
gem "sqlite3"
```

その後：

SQLiteのビルド方法や細かなバージョンは指定しません。利用するOS・Rubyに合う導入方法を調べてください。確認するのは、接続・SQL実行・パラメータのバインド・結果取得という操作です。Rubyのsqlite3 Gemと、ターミナルで使うSQLite CLIの役割も区別してください。

```bash
bundle install
```

---

## Step 2: DBファイルを作成する

```bash
mkdir -p db
sqlite3 db/development.sqlite3
```

プロンプトが表示されれば成功です。

---

## Step 3: テーブルを作成する

`users` テーブルを作成してください。

### 要件

* id（主キー）
* name（文字列）
* email（文字列）

---

## Step 4: テスト用データを投入する

最低2件以上のユーザーを登録してください。

例：

* Alice
* Bob

---

## Step 5: SQLでデータを確認する

```sql
SELECT * FROM users;
```

結果が確認できればOKです。

---

## Step 6: RubyからDB接続できることを確認する

以下の要件を満たす簡単なスクリプトを作成してください：

### 要件

* SQLite3 に接続できる
* `SELECT * FROM users` を実行できる
* 結果がRubyのデータとして取得できる

### ヒント

* `SQLite3::Database.new` を使う
* `execute` でSQLを実行できる

---

## Step 7: ControllerからDBにアクセスする方法を考える

この段階では設計は自由ですが、以下の問いに答えられるようにしてください：

### 問い

* Controllerの中からDB接続はどう取得するか？
* 毎回接続するのか？再利用するのか？
* 接続情報はどこに置くべきか？

### ヒント

* ControllerBase に共通処理を置くという発想はすでに学んでいるはず
* インスタンス変数で保持する方法もある

※ この時点では「正解」はありません
※ まずは「動く最小構成」でよいです

---

## Step 8: テストデータを制御する方法を考える

テストを書く上で重要なのは、

> テストごとにDBの状態をコントロールできること

です。

### 問い

* テストごとにデータをどう初期化するか？
* 既存データをどうリセットするか？
* テストが互いに影響しないようにするにはどうするか？

### ヒント

* 全削除してからinsertする方法が最もシンプル
* トランザクションを使う方法もある（ただし今回は必須ではない）

---

## Step 9: Rackテスト環境の確認

これまでのフェーズで使っているはずですが、以下が使えることを確認してください：

* `env_for`
* Router経由でControllerを呼び出せる

---

## ここまででできている状態

以下がすべて満たされていればOKです：

* SQLiteのDBが存在する
* usersテーブルがある
* RubyからSQLを実行できる
* ControllerからDBにアクセスする方法が決まっている（仮でもOK）
* テストでデータをコントロールできる

---

## トラブルシューティング

---

### ❌ 「no such table」

→ テーブル作成漏れ

---

### ❌ Rubyから接続できない

→ sqlite3 gem のインストール確認

---

### ❌ テストが不安定

→ データ初期化ができていない可能性が高い

---

## この準備の意図

このフェーズではあえて以下をやりません：

* ORM
* Model層
* migration
* schema管理

理由はシンプルです：

> 「生SQLのつらさ」を体験することが目的だから

---

### 要件

* `users` テーブルがある
* テスト開始時に必要なデータを投入できる
* 各テストが独立するようにできる

### 推奨

* テストごとにDBを作り直す
* あるいはトランザクションで巻き戻す
  ※ ただしこの段階では、まずは単純な方法でよい

---

## 演習課題

---

## Step 1: まずは一覧表示をしたいという失敗テストを書く（RED）

最初に、Controller から `users` 一覧を表示したいという要求を固定します。

### テスト例

```ruby
def test_users_index_displays_all_users
  seed_users([
    { id: 1, name: "Alice", email: "alice@example.com" },
    { id: 2, name: "Bob", email: "bob@example.com" }
  ])

  router = Router.new
  router.get "/users", to: "users#index"

  status, _, body = router.call(env_for("/users"))

  assert_equal 200, status
  assert_includes body.join, "Alice"
  assert_includes body.join, "Bob"
end
```

```ruby
class UsersController < ControllerBase
  def index
    # まだ何もない
  end
end
```

### 状態

* DBアクセスもViewもまだ整っていなければ失敗するはず

👉 これが RED

---

## Step 2: 最小実装で一覧を表示する（GREEN）

### やること

* Controller 内でDBに接続する
* `SELECT` を実行する
* 取得結果をViewまたは `render_html` に渡す

### 注意

* この段階では、あえて Controller にSQLを書いてください
* まだ Model を作ってはいけません

### 課題

実装後、以下を確認してください。

* SQL はどこに書かれたか
* DBの戻り値はどの形だったか
* そのままViewに渡しやすかったか

---

## Step 3: 詳細表示をしたいという失敗テストを書く（RED）

次に、特定のユーザー詳細を表示したくなります。

### テスト例

```ruby
def test_users_show_displays_single_user
  seed_users([
    { id: 1, name: "Alice", email: "alice@example.com" }
  ])

  router = Router.new
  router.get "/users/:id", to: "users#show"

  status, _, body = router.call(env_for("/users/1"))

  assert_equal 200, status
  assert_includes body.join, "Alice"
  assert_includes body.join, "alice@example.com"
end
```

```ruby
class UsersController < ControllerBase
  def show
    # まだ何もない
  end
end
```

👉 RED

---

## Step 4: 最小実装で詳細表示を通す（GREEN）

### やること

* path parameter から `id` を取得する
* `WHERE id = ?` のSQLを実行する
* 1件分の結果を表示する

### 課題

以下を観察してください。

* 一覧と詳細でSQLが別々に書かれていないか
* DB結果の扱いが統一されているか
* `.first` のような処理が必要になっていないか

---

## Step 5: 「存在しないID」の振る舞いを先にテストで決める（RED）

ユーザーが見つからない場合の仕様を先に決めます。

### 候補

* 404を返す
* 200で「Not Found」を表示する
* 例外を発生させる

### テスト例（404にする場合）

```ruby
def test_users_show_returns_404_when_user_not_found
  seed_users([])

  router = Router.new
  router.get "/users/:id", to: "users#show"

  status, _, _ = router.call(env_for("/users/999"))

  assert_equal 404, status
end
```

### 注意

ここも正解は1つではありません。
**どの振る舞いにするかを先に決め、テストで固定すること** が重要です。

👉 RED

---

## Step 6: 選んだ仕様を最小実装する（GREEN）

### やること

* Step 5 で決めた仕様に従って実装する

### 課題

* なぜその仕様にしたのか説明できるようにする

---

## Step 7: SQLの結果形式がつらいことを体験するためのテストを書く（RED）

ここでは「動く」ことではなく、「つらさ」を見える化します。

### 課題

一覧表示または詳細表示で、次のような欲求が出るようにしてみてください。

* `user["name"]` のように触りたい
* あるいは `row[:name]` のように触りたい
* 結果のキー形式が不統一だと困る

### テスト例

```ruby
def test_user_row_shape_is_used_in_view
  seed_users([
    { id: 1, name: "Alice", email: "alice@example.com" }
  ])

  router = Router.new
  router.get "/users", to: "users#index"

  status, _, body = router.call(env_for("/users"))

  assert_equal 200, status
  assert_includes body.join, "Alice"
end
```

### 課題

このテストを通すために書いたViewやControllerを見直し、

* 行データの扱いは自然だったか
* ハッシュ / 配列 / DBライブラリ固有の形がそのまま漏れていないか

を確認してください。

👉 RED → GREEN の後に必ず振り返ること

---

## Step 8: SQLの重複が見えるように、2つ目の取得処理を追加する（RED）

次に、同じ `users` テーブルに対して別条件の取得が欲しくなる状況を作ります。

### 例

* 名前で検索する
* email で検索する

### テスト例

```ruby
def test_users_search_by_name
  seed_users([
    { id: 1, name: "Alice", email: "alice@example.com" },
    { id: 2, name: "Bob", email: "bob@example.com" }
  ])

  router = Router.new
  router.get "/users/search", to: "users#search"

  status, _, body = router.call(env_for("/users/search?name=Bob"))

  assert_equal 200, status
  assert_includes body.join, "Bob"
  refute_includes body.join, "Alice"
end
```

```ruby
class UsersController < ControllerBase
  def search
    # まだ何もない
  end
end
```

👉 RED

---

## Step 9: 最小実装で検索を通す（GREEN）

### やること

* query parameter を取得する
* 条件付きのSQLを書く
* 結果を表示する

### 観察ポイント

* 一覧・詳細・検索でSQLが増えていないか
* 似たような処理が繰り返されていないか
* DB接続を毎回意識していないか

---

## Step 10: DB接続の扱いがつらいことを観察する

### 課題

Controller を見返して、次のような重複がないか確認してください。

* DB接続処理
* SQL実行処理
* 結果変換処理
* 0件時の扱い
* Viewに渡す形の調整

### 気づき

ここで到達してほしい理解は：

> 「Controller は画面処理を書く場所であって、
> DBアクセスの詳細を書く場所ではない」

---

## Step 11: まずは“雑でも通る”リファクタリングをする（REFACTOR）

この段階では、まだ Model を作らなくて構いません。
ただし、つらさが見えるように最低限整理します。

### 課題

必要なら、以下のような小さな整理をしてください。

* DB接続を `db` メソッドに切り出す
* SQL実行の共通部分を private メソッドに切り出す

### 注意

ここで大きな抽象化をしてはいけません。
**「つらさを残したまま、少しだけ見通しをよくする」** 程度に留めてください。

### 理由

次の Phase 5.2 で、Model の必要性を本格的に体験するためです。

---

## Step 12: 「なぜつらいのか」を言語化する

このフェーズでは、実装そのものと同じくらい、振り返りが重要です。

### 必ず書くこと

以下を箇条書きではなく、自分の言葉で説明してください。

1. なぜ Controller にSQLを書くとつらいのか
2. 一覧・詳細・検索のどこに重複が出たか
3. DBの戻り値はアプリケーションコードにとって自然だったか
4. 次のフェーズでどのような抽象化が欲しくなったか

---

## 発展課題

### 課題1: DB接続エラー時の振る舞いを考える

#### 問い

* DB接続に失敗したらどこで扱うべきか
* Controller が毎回 rescue するべきか

---

### 課題2: ViewにDBライブラリの戻り値をそのまま渡すことの問題を考える

#### 問い

* View がDBライブラリの都合を知ってしまっていないか
* フレームワークの責務分離としてそれは自然か

---

## 提出物

### 1. テストコード

最低限、以下を含むこと：

* ユーザー一覧表示
* ユーザー詳細表示
* 見つからない場合の仕様
* ユーザー検索
* 引用符やSQL断片を含む入力でもクエリの構造が変わらない

### 2. 実装コード

* UsersController
* 必要なView
* テスト用DBセットアップコード

### 3. 振り返りメモ（最重要）

以下について説明してください：

* なぜ生SQLがつらいのか
* どの責務が Controller に漏れ出していたか
* 次にどんな抽象化が欲しくなったか
* なぜそれを「Model」と呼びたくなるのか

---

## レビュー観点

* RED → GREEN → REFACTOR を守れているか
* テストが画面仕様だけでなく設計上の痛みも固定しているか
* Controller にSQLを書いた結果のつらさを具体的に説明できているか
* 不要な早すぎる抽象化をしていないか
* 次フェーズへの問題意識が明確になっているか

---

## AI活用

### OK

* SQLの基本構文の確認
* SQLite3 の使い方の確認
* テスト粒度の相談
* 「どこがつらいか」の壁打ち

### NG

* ORM風実装の先回り
* Model 層の先行実装
* 完成コードの出力
* 解答の丸写し

---

## よくある失敗

### 1. 早くModelを作りたくなってしまう

→ このフェーズでは我慢すること
→ まずは「痛み」を十分に体験する

### 2. SQLをhelperやprivateメソッドに隠して満足してしまう

→ それでは責務分離の本質は解決していない

### 3. DBの戻り値を自然なオブジェクトだと思い込む

→ それが本当にアプリケーションコードにとって扱いやすいかを考える

### 4. テストがただの画面表示確認だけになる

→ 設計上のつらさを観察し、言語化することが重要

### 5. REFACTORで先回りしすぎる

→ Phase 5.2 以降の学びを潰さないこと

---

## このフェーズの本質

このフェーズで得るべき理解は、

> ORM は最初から欲しかったのではなく、
> 生SQLと生の行データをアプリケーションコードで扱うつらさから必要になった

ということです。

このフェーズは、あえて不便な状態を経験するためのものです。
ここで十分に痛みを感じることで、次のフェーズで導入する Model 層や ORM の意味が、本当に腹落ちします。

---

## 次フェーズへの接続

ここまで来ると、自然に次の欲求が生まれているはずです。

* `UsersController` にSQLを書きたくない
* `users` テーブルへのアクセスを1箇所にまとめたい
* DBの1行をもっと自然な形で扱いたい

次のフェーズでは、これを解決するために

> 1テーブル専用の Model

を TDD で導入します。

---

## 最後に

このフェーズでは、「綺麗な設計」に到達することは目的ではありません。

大切なのは、

* どんな痛みが出たか
* それをどのテストで固定したか
* なぜ次の抽象化が必要になるのか

を、自分の言葉で説明できるようになることです。

ここを丁寧に経験しておくと、Model / ORM は「便利だから使うもの」ではなく、**必要だから生まれるもの**として理解できるようになります。

---

[← 前へ: Phase 4.7](./phase-4-7.md) | [目次](./README.md#カリキュラムテキスト) | [次へ: Phase 5.2 →](./phase-5-2.md)
