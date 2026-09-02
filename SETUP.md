# セットアップと環境の確認

[← 前へ: README](./README.md) | [目次](./README.md#カリキュラムテキスト) | [次へ: Phase 1 →](./phase-1.md)

基準となるRuby・Rackは[README](./README.md)を参照してください。この教材は特定OSのインストールマニュアルではありません。必要な機能と確認方法を示すので、OS・シェル・ライブラリの版による違いは公式ドキュメントやエラーメッセージから調べて解決してください。

## 1. 必要なツールを用意する

自分の環境に合う方法でRuby、Bundler、Git、HTTPクライアント（curlなど）、OpenSSL、SQLite CLIを導入します。Rubyのバージョン管理ツールやOSのパッケージマネージャの選択は問いません。Phase 1のHTTP/1.1観察にはRubyのTCPクライアントを使うので、telnetの追加導入は任意です。演習用サーバはloopbackで起動し、第三者のWebサイトへの接続は不要です。

以下は確認コマンドの例です。

```console
ruby --version
bundle --version
git --version
curl --version
openssl version
sqlite3 --version
```

Rubyが意図した版で起動し、必要なコマンドが見つかることを確認します。見つからなければ、インストール状況やPATH、選択中のRubyを調べてください。Bundlerは使用するRubyと互換性のある版を選びます。

たとえばSQLite CLIはmacOSのHomebrewでは`brew install sqlite`、Debian/Ubuntu系では`sudo apt-get install sqlite3`で導入できます。これらは例であり、特定のOSリリースやパッケージマネージャを必須にはしません。Windowsなどでは自分の環境に合う配布物とシェルの操作を調べます。

SQLite CLIとRubyのsqlite3 Gemは別の入口です。教材ではSQLiteの同梱・ソースビルド・システムライブラリの利用のいずれも指定しません。Gemの導入時に追加の開発ツールが必要なら、その環境向けのインストール手順を確認してください。

## 2. Gemの依存関係を用意する

教材をcloneし、そのルートでGemfileを確認します。既に取得している場合は再cloneする必要はありません。

```console
git clone https://github.com/speee/training-web-app.git
cd training-web-app
bundle install
bundle exec rake test
```

教材リポジトリの`.ruby-version`と`Gemfile.lock`は、保守時の動作確認を再現するための記録です。ここでは記録された組み合わせを試せますが、以後の演習で補助ツールの版を揃えることまでは要求しません。実装とテストは別の作業ディレクトリに置きます。

期待結果は、依存関係の導入成功、`Markdown lint passed`、`Rack 3 compatibility checks passed`、テストの失敗・エラーがないことです。表示の文言や件数はバージョンによって異なります。テストにはloopbackへのTCP接続とSQLite/OpenSSLのCLIが必要です。

## 3. 演習用の作業領域を用意する

教材ルートのRakefileは教材の品質確認用です。演習には別のディレクトリとRakefileを用意し、教材側を上書きしないでください。以下の補助スクリプトは任意です。同じ構成を自分で作っても構いません。

```console
ruby script/prepare_exercise.rb work
cd work
bundle install
bundle exec rake test
```

コピーされるのは`.ruby-version`、`Gemfile`、[starterのRakefile](./starter/Rakefile)・[test_helper](./starter/test/test_helper.rb)・[最小テスト](./starter/test/sample_test.rb)です。教材側のlockfileはコピーしません。`bundle install`で自分の環境に合う依存関係を解決し、生成された`Gemfile.lock`を自分のコードと一緒に管理してください。

教材からコピーしたコードの再配布に備え、[LICENSE-CODE](./LICENSE-CODE)（BSD-2-Clauseの著作権表示・条件・免責条項）もコピーします。この許諾の対象は教材由来のコードです。受講者が独自に書いたコードにBSD-2-Clauseを適用する義務はありません。本文も転載する場合を含め、詳しくは[ライセンスの適用範囲](./README.md#適用範囲)を参照してください。

期待結果は最小テストが成功し、`coverage/index.html`にカバレッジレポートが生成されることです。設定や出力が異なる場合は使っている版のドキュメントで確認してください。最小テストだけではアプリのカバレッジは得られません。実装を追加し、test_helperの後にrequireします。

`lib/`、`app/`、`bin/`、`db/`、`views/`も作成されますが、サーバ・Router・Controller・ORMなどの解答は含みません。既存の`work/`がある場合は上書きせず失敗します。以下では作業ディレクトリを`work/`と呼びますが、名前や配置は変更して構いません。`work/`は教材リポジトリのGit管理対象外なので、成果は別のリポジトリなどで保存してください。

### 環境差に遭遇したら

1. 実行中のRuby・Gemの版と、実際のエラーメッセージを確認する。
2. その操作の目的（例: テストを実行する、SQLの値をバインドする）を整理する。
3. 使用中の版の公式ドキュメントや変更履歴から、対応するAPI・コマンドを調べる。
4. 最小のコードやテストで確かめてから演習に反映し、必要な依存範囲や設定を自分のプロジェクトに記録する。

たとえばテストツールの設定方法が変わっても、失敗を先に確かめ、実装し、リファクタリングする流れは変わりません。DBライブラリの版が違っても、接続・SQL実行・パラメータのバインド・結果取得を確認する観点は同じです。

## 4. 各Phaseの実行と引き継ぎ

以下のファイル名は起動入口の推奨名です。自作コードを別名にした場合はコマンドを読み替えてください。`server.rb`、`tls_server.rb`、`config.ru`、`bin/server`、`bin/console`は**該当演習で自分で作成するファイル**です。環境準備だけでは起動できません。テストは`test/**/*_test.rb`に置きます。

| Phase | 前提・追加するファイル | 実行コマンド | 実装後の期待結果 |
| --- | --- | --- | --- |
| [1](./phase-1.md) | `server.rb`（Socketによる自作サーバ） | `bundle exec ruby server.rb`、別端末で`curl -i http://localhost:3000/` | 自分で組み立てたHTTPレスポンス |
| [2](./phase-2.md) | `webrick_server.rb`に起動例を保存 | `bundle exec ruby webrick_server.rb`、別端末で`curl http://localhost:3000/` | `Hello from WEBrick` |
| [3.1](./phase-3-1.md) | `config.ru`、Phase 1のサーバ | `bundle exec rackup -s webrick -o 127.0.0.1 -p 3000 config.ru`、別端末で`curl http://localhost:3000/` | `Hello Rack`、その後は自作サーバでも同じ応答 |
| [3.2](./phase-3-2.md) | Phase 3.1のサーバ、`test/test_helper.rb` | `bundle exec rake test` | 並行処理テスト成功、`coverage/index.html`生成 |
| [3.3](./phase-3-3.md) | `tls_server.rb`、`key.pem`、`cert.pem` | Phase本文の`openssl req`、`bundle exec ruby tls_server.rb`、別端末で`curl --http1.1 --cacert cert.pem https://localhost:3001/` | ローカル自己署名証明書によるHTTPS応答 |
| [4.1](./phase-4-1.md) | Rackアプリとテスト環境 | `bundle exec rake test` | HTTPメソッド・パスに応じたルーティングのテスト成功 |
| [4.2](./phase-4-2.md) | Router、env生成ヘルパー | `bundle exec rake test` | HTTPメソッド・パス・動的ルートのテスト成功 |
| [4.3](./phase-4-3.md) | Router、Request、Controller | `bundle exec rake test` | Controller/Actionの呼び出し成功 |
| [4.4](./phase-4-4.md) | ControllerBase | `bundle exec rake test` | render/redirectと小文字ヘッダのテスト成功 |
| [4.5](./phase-4-5.md) | Controller、`views/` | `bundle exec rake test` | HTML/ERB描画のテスト成功 |
| [4.6](./phase-4-6.md) | Rackアプリ、Request/Params | `bundle exec rake test` | パス・クエリ・フォームパラメータのテスト成功 |
| [4.7](./phase-4-7.md) | ControllerBase | `bundle exec rake test` | before_actionのテスト成功 |
| [5.1](./phase-5-1.md) | `db/development.sqlite3`とusersテーブル | `mkdir -p db`、`sqlite3 db/development.sqlite3`、`bundle exec rake test` | SQLで登録・取得可能。テストは開発DBと分離 |
| [5.2](./phase-5-2.md) | DB接続、Model | `bundle exec rake test` | 行からModelへの変換テスト成功 |
| [5.3](./phase-5-3.md) | DB・Modelを読み込む`bin/console` | `bundle exec ruby bin/console` | IRBが起動し`User.all`などを実行可能。終了は`exit` |
| [5.4](./phase-5-4.md) | Model、DB接続 | `bundle exec rake test` | 各属性を読み取るテスト成功 |
| [5.5](./phase-5-5.md) | Model、DB接続 | `bundle exec rake test` | all/find/whereのテスト成功 |
| [5.6](./phase-5-6.md) | save、id、DB接続 | `bundle exec rake test` | UPDATE/DELETEのテスト成功 |
| [5.7](./phase-5-7.md) | Modelと保存処理 | `bundle exec rake test` | 不正な値を保存しないテスト成功 |
| [5.8](./phase-5-8.md) | 複数テーブル、Model、BaseModel | `bundle exec rake test` | 複数Modelで共通化したCRUDのテスト成功 |
| [5.9](./phase-5-9.md) | 自作ORMとテスト | `bundle exec rake test`、既存コードとRailsを読解 | 既存テストを維持し、自作ORMの限界を説明できる |
| [6.1](./phase-6-1.md) | 全コンポーネントを起動する`bin/server` | `bundle exec rake test`、`bundle exec ruby bin/server`、ブラウザで`http://localhost:3000/` | 選んだ題材の一覧・作成・更新・削除とエラーケースを確認 |

サーバを終了して次のサーバを起動してください（`Ctrl-C`）。ポート3000（HTTP）または3001（HTTPS）が使用中なら停止するか設定を変更します。HTTPSの既定ポート443と異なるため、Phase 3.3ではURLに`:3001`が必要です。`curl --cacert cert.pem`は自分で生成した証明書を信頼対象に指定します。比較用の`curl -k`は証明書の信頼性・ホスト名の検証を無効にし、接続先のなりすましを検出できなくなるので、ローカル演習限定です。`key.pem`は共有・コミットしないでください。

Phase間で`lib/`などの自作コード、テスト、テンプレート、開発DBのスキーマを引き継ぎます。新しいPhaseのためにGemfileを作り直したり、前の実装を消す必要はありません。起動入口で必要なファイルをrequireする責務は演習側にあります。

### サーバの待受先を確認する

全Phaseで[READMEの安全上の注意](./README.md#安全上の注意教育用本番利用不可)を守ります。自作サーバのホスト引数は`127.0.0.1`に固定し、WEBrickは`BindAddress: "127.0.0.1"`、rackupは`-o 127.0.0.1`を明示してください。

起動後はOSのソケット一覧（macOSなら`lsof -nP -iTCP:3000 -sTCP:LISTEN`、Linuxなら`ss -ltn`など）で、実際の待受先が`127.0.0.1`（IPv6を選んだ場合は`::1`）であることを確認します。HTTPSではポート3001も確認します。`*`・`0.0.0.0`・`[::]`など全インターフェースの表示なら停止して設定を直してください。localhostへ接続できたことだけでは、待受がローカル限定とは確認できません。

### 証明書・秘密鍵の取扱い

Phase 3.3の生成コマンドを実行する前に、**演習成果を保存するリポジトリ**の`.gitignore`へ以下を追加します。セットアップスクリプトで作った新規演習には[starter/.gitignore](./starter/.gitignore)がコピーされます。既存の演習や別リポジトリには自分で追加してください。

```gitignore
# ローカルTLS演習の生成物
*.pem
*.key
```

`key.pem`は秘密鍵であり、共有・コミットしません。`cert.pem`は公開証明書ですが、この演習ではどちらもローカルで生成するため管理対象外にします。秘密鍵を別名・別形式で保存した場合も、そのパスをignoreへ追加してください。配信用ディレクトリにも置きません。

演習リポジトリで、生成前に次を確認します（教材の`work/`をまだ別リポジトリにしていない場合は、成果をGit管理するときにも確認してください）。

```bash
git check-ignore -v key.pem cert.pem
git ls-files -- key.pem cert.pem
git diff --cached --name-only
```

最初のコマンドでignore規則が表示され、2つ目で追跡中のファイルが表示されず、コミット予定にも鍵がないことを確認します。`.gitignore`は追跡済みのファイルには効きません。追跡済みなら`git rm --cached -- key.pem cert.pem`（実際に追跡しているファイルのみ指定）で管理対象から外します。コミット・共有済みの秘密鍵は漏えいしたものとして使用をやめ、鍵と証明書を作り直してください。ignore追加や最新コミットでの削除だけでは履歴から消えません。

生成は`umask 077`を設定したシェルで行い、生成後も`chmod 600 key.pem`などで所有者だけが読み書きできるようにします。Windowsなどでは相当するファイル権限を設定します。秘密鍵の内容をログや提出資料へ貼り付けないでください。

## 5. 発展課題と検証の範囲

Sinatra/Railsの調査は任意の発展課題であり、基準Gemfileには含めません。既存の検証済みアプリを読解するか、`work/`と独立したプロジェクトを作り、そのフレームワークに対応するRuby・Gemfile・lockfileを使ってください。基準Gemfileへ無条件に追加しないでください。

教材の`bundle exec rake test`は新規一時ディレクトリを使い、TCP/Thread、WEBrickとrackupの本文コード、OpenSSLの証明書生成・読み込み、ERB/JSON/IRB、SQLite CRUDとCLI、演習作業領域の生成・Minitest/SimpleCovを確認します。CIのmacOS 15とUbuntu 24.04は検証例であり、対応OSを限定するものではありません。テストでは補助ツールのリリース番号の一致ではなく、必要な操作ができることを確認します。

これはPhase 1〜6の**環境と依存APIのスモークテスト**です。学習者のRouter・ORMなどの完成実装や、全演習の解答を通したE2Eテストではありません。各Phaseの受け入れ条件は上表と本文に従い、実装したテスト・ブラウザ操作で別途確認してください。

---

[← 前へ: README](./README.md) | [目次](./README.md#カリキュラムテキスト) | [次へ: Phase 1 →](./phase-1.md)
