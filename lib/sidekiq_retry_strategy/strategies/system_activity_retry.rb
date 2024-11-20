module SidekiqRetryStrategy
  module Strategies
    module SystemActivityRetry
      extend ActiveSupport::Concern
      include CustomRetryLogic

      class_methods do
        def retry_params
          params = fetch_retry_params("system_activity_retry")
          params
        end
      end
    end
  end
end
