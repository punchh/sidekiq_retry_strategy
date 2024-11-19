# frozen_string_literal: true

require "p_retry_strategy/version"
require "p_retry_strategy/configuration"
require "p_retry_strategy/retry_logic_helpers"
require "p_retry_strategy/custom_retry_logic"
require "p_retry_strategy/strategies/default_retry"

module SidekiqRetryStrategy
  # Config loads from initializer in the Rails app, using ENV overrides.
end
