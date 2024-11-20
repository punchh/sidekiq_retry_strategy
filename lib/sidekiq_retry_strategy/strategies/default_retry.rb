module SidekiqRetryStrategy
  module Strategies
    module DefaultRetry
      extend ActiveSupport::Concern
      include CustomRetryLogic

      class_methods do
        def retry_params
          params = fetch_retry_params("default_retry_strategy")
          params
        end
      end
    end
  end
end

