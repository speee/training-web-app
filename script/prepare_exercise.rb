# frozen_string_literal: true

require "fileutils"

abort "Usage: ruby script/prepare_exercise.rb NEW_DIRECTORY" unless ARGV.size == 1
root = File.expand_path("..", __dir__)
target = File.expand_path(ARGV.fetch(0))
# mkdir refuses existing directories (including symlinks), so no learner files are overwritten.
Dir.mkdir(target)
# Each learner resolves and records dependencies in their own environment.
%w[Gemfile .ruby-version LICENSE-CODE].each do |name|
  FileUtils.cp(File.join(root, name), target)
end
FileUtils.cp_r(File.join(root, "starter", "."), target)
%w[lib app bin db views].each { |name| FileUtils.mkdir_p(File.join(target, name)) }
puts "Exercise workspace created: #{target}"
