module SidekiqRetryStrategy
  module RetryLogicHelpers
    extend ActiveSupport::Concern

    class_methods do
      def fetch_retry_params(strategy_name)
        SidekiqRetryStrategy.config.retry_settings(strategy_name)
      end

      def expand_delays_array(delays, max_retries)
        delays.length < max_retries ? delays + [delays.last] * (max_retries - delays.length) : delays
      end
    end
  end
end
