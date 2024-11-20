# frozen_string_literal: true
require_relative "test_helper"
require "sidekiq/testing"
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

    def self.is_kill_on_exception(exception, _jobhash, _count)
      exception.is_a?(RuntimeError)
    end

    def self.is_discard_on_exception(exception, _jobhash, _count)
      exception.is_a?(ArgumentError)
    end

    def self.is_retriable_on_exception(exception, _jobhash, _count)
      exception.is_a?(RuntimeError) || super
    end
  end

  test "override is_kill_on_exception in worker to kill on RuntimeError" do
    runtime_error = RuntimeError.new("Fatal error")
    assert_equal true, OverrideWorker.is_kill_on_exception(runtime_error, @jobhash, 1)
  end

  test "override is_discard_on_exception in worker to discard on ArgumentError" do
    argument_error = ArgumentError.new("Discardable error")
    assert_equal true, OverrideWorker.is_discard_on_exception(argument_error, @jobhash, 1)
  end

  test "override is_retriable_on_exception in worker to retry on RuntimeError" do
    runtime_error = RuntimeError.new("Retriable error")
    assert_equal true, OverrideWorker.is_retriable_on_exception(runtime_error, @jobhash, 1)
  end

  test "sidekiq_retry_in returns correct delay based on retry_params" do
    Sidekiq::Testing.fake! do
      TestWorker.perform_async
      assert_equal 1, TestWorker.jobs.size
    end

    count = 2
    retry_logic = TestWorker.sidekiq_retry_in_block
    delay = retry_logic.call(count, @exception, @jobhash)
    expected_delay = TestWorker.retry_params["delays"][count]

    assert_in_delta expected_delay, delay, 60
  end

  test "sidekiq_retry_in discards job after max retries" do
    Sidekiq::Testing.fake! do
      max_retries = TestWorker.retry_params["max_retries"]
      retry_logic = TestWorker.sidekiq_retry_in_block

      max_retries.times do |i|
        assert_not_equal :discard, retry_logic.call(i, @exception, @jobhash)
      end

      # Expects :discard after exceeding max retries
      assert_equal :discard, retry_logic.call(max_retries, @exception, @jobhash)
    end
  end
end
