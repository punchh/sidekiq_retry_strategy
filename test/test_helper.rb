# frozen_string_literal: true

require "minitest/autorun"
require "sidekiq/testing"
require 'active_support'
require 'active_support/testing/time_helpers'
require 'active_support/test_case'
require_relative "../lib/p_retry_strategy" # Load the gem

Sidekiq::Testing.fake!
