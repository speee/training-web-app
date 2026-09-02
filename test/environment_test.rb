# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "open3"
require "rbconfig"
require "socket"
require "net/http"
require "openssl"
require "erb"
require "json"
require "irb"
require "sqlite3"
require "timeout"

class EnvironmentTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  RUBY = RbConfig.ruby

  def ruby_example(file, heading)
    section = File.read(File.join(ROOT, file)).split(heading, 2).fetch(1)
    section.match(/```ruby\n(.*?)\n```/m)[1]
  end

  def capture!(*command, **options)
    output, status = Open3.capture2e(*command, **options)
    assert status.success?, "#{command.join(' ')} failed:\n#{output}"
    output
  end

  def test_reference_ruby
    assert_equal File.read(File.join(ROOT, ".ruby-version")).strip, RUBY_VERSION
    puts "Validated: #{RUBY_DESCRIPTION}; SQLite engine #{SQLite3::SQLITE_VERSION}"
  end

  def test_phase_1_socket_and_threads
    Timeout.timeout(10) do
      TCPServer.open("127.0.0.1", 0) do |server|
        worker = Thread.new do
          connection = server.accept
          connection.write("Hello\n")
        ensure
          connection&.close
        end
        begin
          TCPSocket.open("127.0.0.1", server.addr[1]) { |client| assert_equal "Hello\n", client.gets }
          worker.value
        ensure
          worker.kill.join if worker.alive?
        end
      end
    end
  end

  def with_documented_server(file, heading, rackup: false)
    Dir.mktmpdir("curriculum-server-") do |directory|
      port = TCPServer.open("127.0.0.1", 0) { |socket| socket.addr[1] }
      source = ruby_example(file, heading).sub("Port: 3000", "Port: #{port}")
      path = File.join(directory, rackup ? "config.ru" : "server.rb")
      File.write(path, source)
      command = if rackup
        [RUBY, "-S", "rackup", "-s", "webrick", "-o", "127.0.0.1", "-p", port.to_s, path]
      else
        [RUBY, path]
      end
      File.open(File.join(directory, "server.log"), "w+") do |log|
        pid = Process.spawn(*command, out: log, err: log)
        begin
          response = Timeout.timeout(15) do
            loop do
              begin
                http = Net::HTTP.new("127.0.0.1", port, nil)
                http.open_timeout = 1
                http.read_timeout = 2
                break http.get("/")
              rescue Errno::ECONNREFUSED
                sleep 0.05
              end
            end
          end
          assert_equal "200", response.code
          yield response
        ensure
          Process.kill("INT", pid) rescue Errno::ESRCH
          begin
            Timeout.timeout(5) { Process.wait(pid) }
          rescue Timeout::Error
            Process.kill("KILL", pid)
            Process.wait(pid)
          end
          log.rewind
          warn log.read if !passed?
        end
      end
    end
  end

  def test_phase_2_webrick_example
    with_documented_server("phase-2.md", "### Step 1:") do |response|
      assert_equal "Hello from WEBrick", response.body
    end
  end

  def test_phase_3_rackup_example
    with_documented_server("phase-3-1.md", "### Step 3:", rackup: true) do |response|
      assert_equal "Hello Rack", response.body
      assert_equal "text/plain", response["content-type"]
    end
  end

  def test_phase_3_tls_tools
    Dir.mktmpdir("curriculum-tls-") do |directory|
      capture!("openssl", "req", "-x509", "-newkey", "rsa:2048", "-nodes", "-days", "1",
        "-subj", "/CN=localhost", "-keyout", "key.pem", "-out", "cert.pem", chdir: directory)
      context = OpenSSL::SSL::SSLContext.new
      context.cert = OpenSSL::X509::Certificate.new(File.read(File.join(directory, "cert.pem")))
      context.key = OpenSSL::PKey.read(File.read(File.join(directory, "key.pem")))
      assert context.cert.check_private_key(context.key)
      assert context.setup
    end
  end

  def test_phase_4_templates_and_phase_5_console
    assert_equal "<h1>Alice</h1>", ERB.new("<h1><%= name %></h1>").result_with_hash(name: "Alice")
    assert_equal({ "name" => "Alice" }, JSON.parse(JSON.generate(name: "Alice")))
    assert defined?(IRB)
  end

  def test_phase_5_sqlite_and_cli
    assert_match(/\A3\./, capture!("sqlite3", "--version"))
    Dir.mktmpdir("curriculum-db-") do |directory|
      path = File.join(directory, "development.sqlite3")
      SQLite3::Database.open(path) do |db|
        db.execute("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)")
        db.execute("INSERT INTO users (name) VALUES (?)", ["Alice"])
        assert_equal [["Alice"]], db.execute("SELECT name FROM users WHERE id = ?", [1])
        db.execute("UPDATE users SET name = ? WHERE id = ?", ["Bob", 1])
        assert_equal "Bob", db.get_first_value("SELECT name FROM users")
        db.execute("DELETE FROM users WHERE id = ?", [1])
        assert_equal 0, db.get_first_value("SELECT COUNT(*) FROM users")
      end
      assert_equal "0\n", capture!("sqlite3", path, "SELECT COUNT(*) FROM users;")
    end
  end

  def test_fresh_exercise_workspace_and_coverage
    Dir.mktmpdir("curriculum-workspace-") do |directory|
      target = File.join(directory, "work")
      capture!(RUBY, File.join(ROOT, "script/prepare_exercise.rb"), target)
      %w[Gemfile .ruby-version LICENSE-CODE].each do |name|
        assert_equal File.read(File.join(ROOT, name)), File.read(File.join(target, name))
      end
      %w[lib app bin db views].each { |name| assert File.directory?(File.join(target, name)) }
      refute File.exist?(File.join(target, "Gemfile.lock")), "do not impose the CI lockfile on learners"
      env = { "BUNDLE_GEMFILE" => File.join(target, "Gemfile"),
              "BUNDLE_PATH" => File.expand_path(Bundler.settings.path.base_path, Bundler.root),
              "BUNDLE_FROZEN" => "false", "BUNDLE_DEPLOYMENT" => "false" }
      Bundler.with_unbundled_env do
        capture!(env, RUBY, "-S", "bundle", "install", "--local", chdir: target)
        output = capture!(env, RUBY, "-S", "bundle", "exec", "rake", "test", chdir: target)
        assert_includes output, "0 failures, 0 errors"
      end
      assert File.file?(File.join(target, "Gemfile.lock"))
      assert File.file?(File.join(target, "coverage/index.html"))
      _, status = Open3.capture2e(RUBY, File.join(ROOT, "script/prepare_exercise.rb"), target)
      refute status.success?, "existing workspaces must never be overwritten"
    end
  end

  def test_starter_matches_phase_3_instructions
    { "Rakefile" => "# Step 0-2:", "test/test_helper.rb" => "# Step 0-4:",
      "test/sample_test.rb" => "# Step 0-5:" }.each do |file, heading|
      assert_equal ruby_example("phase-3-2.md", heading).strip,
        File.read(File.join(ROOT, "starter", file)).strip
    end
  end
end
