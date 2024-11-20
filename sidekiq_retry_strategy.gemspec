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
  spec.metadata["source_code_uri"] = "https://github.com/your-username/sidekiq_retry_strategy"
  spec.metadata["changelog_uri"]   = "https://github.com/your-username/sidekiq_retry_strategy/blob/main/CHANGELOG.md"

  # Files to include in the gem
  spec.files = Dir.glob("lib/**/*") + ["README.md", "LICENSE.txt"]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment or add any runtime dependencies required for the gem to work
  # Example:
  # spec.add_runtime_dependency "some_dependency", "~> 1.0"
end
