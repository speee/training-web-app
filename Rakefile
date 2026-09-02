desc "Validate documentation and Rack 3 compatibility"
task :test do
  ruby "script/markdown_lint.rb"
  ruby "script/rack3_lint.rb"
  ruby "test/environment_test.rb"
end

task default: :test
