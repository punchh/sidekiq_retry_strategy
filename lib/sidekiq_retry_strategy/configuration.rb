require 'yaml'

module SidekiqRetryStrategy
  class Configuration
    def initialize
      load_retry_settings
    end

    def retry_settings(strategy)
      @retry_settings[strategy.to_s] || @retry_settings["default_retry_strategy"]
    end

    def load_retry_settings
      config_path = Rails.root.join('config', 'p_retry_strategy.yml')
      yaml_settings = YAML.load_file(config_path)

      @retry_settings = {
        "default_retry_strategy" => fetch_from_env("DEFAULT_RETRY_STRATEGY", yaml_settings["default_retry_strategy"]),
        "guest_activity_retry" => fetch_from_env("GUEST_ACTIVITY_RETRY", yaml_settings["guest_activity_retry"]),
        "business_admin_activity_retry" => fetch_from_env("BUSINESS_ADMIN_ACTIVITY_RETRY", yaml_settings["business_admin_activity_retry"]),
        "system_activity_retry" => fetch_from_env("SYSTEM_ACTIVITY_RETRY", yaml_settings["system_activity_retry"])
      }

    rescue StandardError => e
      Rails.logger.error("Error loading retry strategy configuration: #{e.message}")
      @retry_settings = {}
    end

    private

    def fetch_from_env(env_key, default)
      JSON.parse(ENV[env_key] || default.to_json)
    rescue JSON::ParserError
      Rails.logger.error("Error parsing JSON for #{env_key}. Using default retry strategy.")
      default
    end
  end

  def self.config
    @config ||= Configuration.new
  end
end
