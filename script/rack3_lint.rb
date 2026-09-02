# frozen_string_literal: true

require "pathname"
require "rack"
require "rack/lint"
require "rack/mock"

ROOT = Pathname.new(__dir__).join("..").expand_path
PHASE_FILES = Dir.glob(ROOT.join("phase-{3,4}*.md")).sort.freeze

errors = []

PHASE_FILES.each do |path|
  relative_path = Pathname.new(path).relative_path_from(ROOT)

  File.foreach(path).with_index(1) do |line, line_number|
    if line.include?("Rack::Handler")
      errors << "#{relative_path}:#{line_number}: Rack::Handler is not available from Rack 3"
    end

    line.scan(/[\"']([A-Za-z0-9-]+)[\"']\s*(?:=>|\])/).flatten.each do |header_name|
      next unless header_name.include?("-") || %w[Location ETag].include?(header_name)
      next if header_name == header_name.downcase

      errors << "#{relative_path}:#{line_number}: Rack response header must be lowercase: #{header_name}"
    end
  end
end

app = lambda do |_env|
  [200, { "content-type" => "text/plain" }, ["Hello Rack"]]
end

begin
  response = Rack::MockRequest.new(Rack::Lint.new(app)).get("/")
  errors << "Rack::Lint sample returned #{response.status}, expected 200" unless response.status == 200
  unless response["content-type"] == "text/plain"
    errors << "Rack::Lint sample returned an unexpected content-type"
  end
rescue StandardError => e
  errors << "Rack::Lint rejected the documented sample: #{e.class}: #{e.message}"
end

if errors.empty?
  puts "Rack 3 compatibility checks passed (Rack #{Rack.release})"
else
  warn errors.join("\n")
  exit 1
end
