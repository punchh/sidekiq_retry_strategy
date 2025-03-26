module SidekiqRetryStrategy
  module RetryLogicHelpers
    extend ActiveSupport::Concern

    class_methods do
      # Fetch retry parameters from global configuration (YAML/ENV)
      def fetch_retry_params(strategy_name)
        SidekiqRetryStrategy.config.retry_settings(strategy_name)
      end

      # Expand delays array to match the number of retries if needed
      def expand_delays_array(delays, max_retries)
        # Ensures the delays array matches the max retries count
        if delays.length < max_retries
          delays + [delays.last] * (max_retries - delays.length)
        else
          delays
        end
      end
    end
  end
end
