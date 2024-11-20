# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

$LOAD_PATH.unshift(File.expand_path("test", __dir__))

Rake::TestTask.new do |t|
  t.pattern = "test/**/*_test.rb"
end

task default: %i[test]
