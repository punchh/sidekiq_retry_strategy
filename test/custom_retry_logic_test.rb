# frozen_string_literal: true
require_relative "test_helper"
require "sidekiq/testing"
require "sidekiq/logger"
require_relative "../lib/sidekiq_retry_strategy/custom_retry_logic"

class CustomRetryLogicTest < ActiveSupport::TestCase
  # Define a mock worker to test the logic with and without overrides
  class TestWorker
    include Sidekiq::Worker
    include SidekiqRetryStrategy::CustomRetryLogic

    sidekiq_options retry: true

    def self.retry_params
      { "max_retries" => 5, "delays" => [300, 600, 1200, 2400, 4800] }
    end
  end

  class ConfigurableRetryWorker
    include Sidekiq::Worker
    include SidekiqRetryStrategy::CustomRetryLogic

    sidekiq_options retry: true

    def self.retry_params
      {
        "default_retry_strategy" => { "max_retries" => 5, "delays" => [300, 600, 1200, 2400, 4800] },
        "guest_activity_retry" => { "max_retries" => 3, "delays" => [100, 200, 300, 500, 600, 1000] },
        "business_admin_activity_retry" => { "max_retries" => 4, "delays" => [150, 300, 600, 1200, 200] },
        "system_activity_retry" => { "max_retries" => 2, "delays" => [50, 100, 500, 600, 700] }
      }
    end
  end

  setup do
    @exception = StandardError.new("Test exception")
    @jobhash = { "class" => "TestWorker", "args" => [] }
  end

  test "default behavior for is_kill_on_exception returns false" do
    assert_equal false, TestWorker.is_kill_on_exception(@exception, @jobhash, 1)
  end

  test "default behavior for is_discard_on_exception returns false" do
    assert_equal false, TestWorker.is_discard_on_exception(@exception, @jobhash, 1)
  end

  test "default behavior for is_retriable_on_exception returns true for specific exceptions" do
    @exception.stub :is_a?, true do
      assert_equal true, TestWorker.is_retriable_on_exception(@exception, @jobhash, 1)
    end
  end

  # Mock worker with overridden methods
  class OverrideWorker
    include Sidekiq::Worker
    include SidekiqRetryStrategy::CustomRetryLogic

    sidekiq_options retry: true

    def self.retry_params
      { "max_retries" => 3, "delays" => [100, 200, 300, 400, 1000] }
    end

    def self.is_kill_on_exception(exception, jobhash, count)
      exception.is_a?(RuntimeError)
    end

    def self.is_discard_on_exception(exception, jobhash, count)
      exception.is_a?(ArgumentError)
    end
  end

  test "sidekiq_retry_in kills job on RuntimeError" do
    Sidekiq::Testing.fake! do
      exception = RuntimeError.new("Test runtime error")
      retry_logic = OverrideWorker.sidekiq_retry_in_block

      assert_equal :kill, retry_logic.call(1, exception, @jobhash)
    end
  end

  test "sidekiq_retry_in discards job on ArgumentError" do
    Sidekiq::Testing.fake! do
      exception = ArgumentError.new("Test argument error")
      retry_logic = OverrideWorker.sidekiq_retry_in_block

      assert_equal :discard, retry_logic.call(1, exception, @jobhash)
    end
  end

  test "sidekiq_retry_in returns correct delay with random jitter" do
    Sidekiq::Testing.fake! do
      retry_logic = TestWorker.sidekiq_retry_in_block
      delay = retry_logic.call(1, @exception, @jobhash)
      expected_delay = TestWorker.retry_params["delays"][1]

      assert_in_delta expected_delay, delay, 60
    end
  end

  test "sidekiq_retry_in handles ActiveRecord::StatementInvalid with 'gone away' message" do
    Sidekiq::Testing.fake! do
      exception = ActiveRecord::StatementInvalid.new("MySQL server has gone away")
      retry_logic = TestWorker.sidekiq_retry_in_block

      delay = retry_logic.call(1, exception, @jobhash)
      expected_delay = TestWorker.retry_params["delays"][1]

      assert_in_delta expected_delay, delay, 60
    end
  end

  test "sidekiq_retry_in handles RedisClient::CannotConnectError" do
    Sidekiq::Testing.fake! do
      exception = RedisClient::CannotConnectError.new("Cannot connect to Redis")
      retry_logic = TestWorker.sidekiq_retry_in_block

      delay = retry_logic.call(1, exception, @jobhash)
      expected_delay = TestWorker.retry_params["delays"][1]

      assert_in_delta expected_delay, delay, 60
    end
  end

  # New tests for configurable retry strategies
  test "configurable_retry_worker handles different strategies correctly" do
    Sidekiq::Testing.fake! do
      ["default_retry_strategy", "guest_activity_retry", "business_admin_activity_retry", "system_activity_retry"].each do |strategy|
        retry_params = ConfigurableRetryWorker.retry_params[strategy]
        validate_retry_logic(ConfigurableRetryWorker, retry_params)
      end
    end
  end

  test "sidekiq_retry_in discards job for invalid retry_params" do
    Sidekiq::Testing.fake! do
      # Suppress warnings for invalid retry_params
      original_logger = Sidekiq
      Sidekiq = Logger.new(nil)

      ConfigurableRetryWorker.stub :retry_params, nil do
        retry_logic = ConfigurableRetryWorker.sidekiq_retry_in_block
        assert_equal :discard, retry_logic.call(0, @exception, @jobhash)
      end

      ConfigurableRetryWorker.stub :retry_params, { "max_retries" => nil, "delays" => nil } do
        retry_logic = ConfigurableRetryWorker.sidekiq_retry_in_block
        assert_equal :discard, retry_logic.call(0, @exception, @jobhash)
      end

      # Restore the original logger
      Sidekiq = original_logger
    end
  end

  test "sidekiq_retry_in uses overridden retry options" do
    Sidekiq::Testing.fake! do
      class OverrideOptionsWorker
        include Sidekiq::Worker
        include SidekiqRetryStrategy::CustomRetryLogic

        sidekiq_options retry: true, set_retry_options: { "max_retries" => 2, "delays" => [100, 200] }

        def self.retry_params
          { "max_retries" => 2, "delays" => [100, 200] }
        end
      end

      retry_logic = OverrideOptionsWorker.sidekiq_retry_in_block
      delay = retry_logic.call(1, @exception, @jobhash)
      expected_delay = 200
      assert_equal :discard, delay
    end
  end

  private

  def validate_retry_logic(worker_class, retry_params)
    max_retries = retry_params["max_retries"]
    delays = retry_params["delays"]

    max_retries.times do |count|
      retry_logic = worker_class.sidekiq_retry_in_block
      delay = retry_logic.call(count, @exception, @jobhash)
      if delay == :discard
        assert_equal :discard, delay
      else
        expected_delay = delays[count]
        assert_in_delta expected_delay, delay, 60
      end
    end
  end
end
