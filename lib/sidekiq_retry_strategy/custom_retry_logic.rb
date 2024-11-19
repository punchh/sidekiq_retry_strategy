# frozen_string_literal: true
require 'active_record'
require 'newrelic_rpm'

module SidekiqRetryStrategy
  module CustomRetryLogic
    extend ActiveSupport::Concern
    include RetryLogicHelpers

    included do
      sidekiq_retry_in do |count, exception, jobhash|
        retry_params = self.retry_params

        max_retries = retry_params['max_retries']
        delays = retry_params['delays'].size != max_retries ? self.expand_delays_array(retry_params['delays'], max_retries) : retry_params['delays'] 

        if count >= max_retries
          sidekiq_retries_exhausted_block.call(jobhash, exception)
          :discard
        else
          # Call methods that can be overridden by the worker class
          if is_kill_on_exception(exception, jobhash, count)
            Sidekiq.logger.error("Permanent Failure for #{jobhash['class']} with #{jobhash['args']}: #{exception.message}")
            NewRelic::Agent.notice_error(exception)
            :kill
          elsif is_discard_on_exception(exception, jobhash, count)
            :discard
          elsif is_retriable_on_exception(exception, jobhash, count)
            delays[count] + rand(-60..60) # Adding +- 1 minute
          else
            delays[count] + rand(-60..60) # Adding +- 1 minute
          end
        end
      end

      sidekiq_retries_exhausted do |job, exception|
        Sidekiq.logger.warn "Retries Exhausted for #{job['class']} with args #{job['args']} due to #{exception.message}"
        NewRelic::Agent.notice_error(exception)
      end
    end

    # Define class methods that are overridable by the worker class
    class_methods do
      def is_kill_on_exception(exception, jobhash, count)
        if method_defined_in_worker?(:is_kill_on_exception)
          self.is_kill_on_exception(exception, jobhash, count)
        else
          false # Default behavior; add specific conditions if needed
        end
      end

      def is_discard_on_exception(exception, jobhash, count)
        if method_defined_in_worker?(:is_discard_on_exception)
          self.is_discard_on_exception(exception, jobhash, count)
        else
          false # Default behavior; add specific conditions if needed
        end
      end

      def is_retriable_on_exception(exception, jobhash, count)
        if method_defined_in_worker?(:is_retriable_on_exception)
          self.is_retriable_on_exception(exception, jobhash, count)
        else
          # Default retryable exceptions
          retriable_exceptions = [
            ActiveRecord::ConnectionNotEstablished,
            RedisClient::CannotConnectError
          ]

          # extra condition for ActiveRecord::StatementInvalid with "gone away"
          if exception.is_a?(ActiveRecord::StatementInvalid) && exception.message.include?("gone away")
            retriable_exceptions << ActiveRecord::StatementInvalid
          end

          retriable_exceptions.any? { |e| exception.is_a?(e) }
        end
      end

      private

      def method_defined_in_worker?(method_name)
        self.instance_methods.include?(method_name)
      end
    end
  end
end
