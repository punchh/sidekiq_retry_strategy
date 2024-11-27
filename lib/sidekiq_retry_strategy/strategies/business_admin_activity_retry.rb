module SidekiqRetryStrategy
  module Strategies
    module BusinessAdminActivityRetry
      extend ActiveSupport::Concern
      include CustomRetryLogic

      class_methods do
        def retry_params
          params = fetch_retry_params("business_admin_activity_retry")
          params
        end
      end
    end
  end
end

