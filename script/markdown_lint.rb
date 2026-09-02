# frozen_string_literal: true

require "pathname"
require "uri"

ROOT = Pathname.new(__dir__).join("..").expand_path
MARKDOWN_FILES = Dir.glob(ROOT.join("**/*.md")).reject do |path|
  %w[vendor work].include?(Pathname.new(path).relative_path_from(ROOT).each_filename.first)
end.sort.freeze
KNOWN_PHASES = MARKDOWN_FILES.map do |path|
  match = File.basename(path).match(/\Aphase-(\d+)-(\d+)\.md\z/)
  "#{match[1]}.#{match[2]}" if match
end.compact.freeze
MISSPELLINGS = {
  "NignX" => "Nginx",
  "Scoket" => "Socket",
  "Webrick" => "WEBrick"
}.freeze
REQUIRED_FILES = [ROOT.join("LICENSE")].freeze

errors = []

REQUIRED_FILES.each do |path|
  errors << "missing required file: #{path.relative_path_from(ROOT)}" unless path.file?
end

MARKDOWN_FILES.each do |path|
  relative_path = Pathname.new(path).relative_path_from(ROOT).to_s
  lines = File.readlines(path)
  open_fence = nil

  lines.each_with_index do |line, index|
    line_number = index + 1
    fence_match = line.chomp.match(/\A {0,3}(`{3,}|~{3,})(.*)\z/)

    if open_fence
      if fence_match && fence_match[1][0] == open_fence[:character] &&
          fence_match[1].length >= open_fence[:length] && fence_match[2].strip.empty?
        open_fence = nil
      end
      next
    end

    if fence_match
      info = fence_match[2].strip
      language = info.split(/\s+/).first
      if language && !language.match?(/\A[[:alnum:]_+-]+\z/)
        errors << "#{relative_path}:#{line_number}: invalid code fence language: #{language}"
      end
      open_fence = {
        character: fence_match[1][0],
        length: fence_match[1].length,
        line: line_number
      }
      next
    end

    line.scan(/!?\[[^\]]*\]\(([^)]+)\)/).flatten.each do |raw_target|
      target = raw_target.strip
      target = target[1...target.index(">")] if target.start_with?("<") && target.include?(">")
      next if target.empty? || target.start_with?("#")
      next if target.match?(/\A(?:[a-z][a-z0-9+.-]*:|\/\/)/i)

      local_path = target.split(/[?#]/, 2).first
      local_path = URI::DEFAULT_PARSER.unescape(local_path)
      resolved_path = Pathname.new(path).dirname.join(local_path).cleanpath
      unless resolved_path.exist?
        errors << "#{relative_path}:#{line_number}: broken local link: #{target}"
      end
    end

    line.scan(/\bPhase\s+(\d+\.\d+)\b/i).flatten.each do |phase|
      unless KNOWN_PHASES.include?(phase)
        errors << "#{relative_path}:#{line_number}: unknown phase reference: Phase #{phase}"
      end
    end

    MISSPELLINGS.each do |misspelling, correction|
      if line.include?(misspelling)
        errors << "#{relative_path}:#{line_number}: use #{correction} instead of #{misspelling}"
      end
    end
  end

  if open_fence
    errors << "#{relative_path}:#{open_fence[:line]}: unclosed code fence"
  end
end

if errors.empty?
  puts "Markdown lint passed (#{MARKDOWN_FILES.length} files)"
else
  warn errors.join("\n")
  exit 1
end
