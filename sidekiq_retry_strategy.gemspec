# frozen_string_literal: true

require_relative "lib/sidekiq_retry_strategy/version"

Gem::Specification.new do |spec|
  spec.name          = "sidekiq_retry_strategy"
  spec.version       = SidekiqRetryStrategy::VERSION
  spec.authors       = ["Punchh CAN Team"]
  spec.email         = ["morenobiage@partech.com"]

  spec.summary       = "A retry strategy gem for managing Sidekiq job retries based on custom logic."
  spec.description   = "SidekiqRetryStrategy is a gem that provides custom retry logic for Sidekiq jobs, allowing configuration of retry intervals, exponential backoff, and custom exception handling, based on YAML settings and environment variable overrides."
  spec.homepage      = "https://github.com/punchh/sidekiq_retry_strategy"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  # Metadata for publishing
  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/punchh/sidekiq_retry_strategy"
  spec.metadata["changelog_uri"]   = "https://github.com/punchh/sidekiq_retry_strategy/blob/main/CHANGELOG.md"

  # Files to include in the gem
  spec.files = Dir.glob("lib/**/*") + ["README.md", "LICENSE.txt"]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_runtime_dependency "sidekiq", "~> 7.2", ">= 7.2.4"
  spec.add_runtime_dependency "activesupport", "~> 7.1", ">= 7.1.3.2"
  spec.add_runtime_dependency "activerecord", "~> 7.1"
  spec.add_runtime_dependency "sidekiq-unique-jobs", "~> 8.0", ">= 8.0.10"
  spec.add_runtime_dependency "sidekiq-failures", "~> 1.0", ">= 1.0.4"
  spec.add_runtime_dependency "newrelic_rpm", "~> 9.11", ">= 9.11.0"

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
