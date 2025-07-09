# frozen_string_literal: true

module WebService
  class Configuration
    attr_accessor :max_requests_per_minute, :allowed_origins, :enable_cors, 
                  :log_level, :token_expiry_hours

    def initialize
      @max_requests_per_minute = 100
      @allowed_origins = ['*']
      @enable_cors = true
      @log_level = :info
      @token_expiry_hours = 24
    end

    def self.configure
      @configuration ||= new
      yield(@configuration) if block_given?
      @configuration
    end

    def self.configuration
      @configuration ||= new
    end
  end
end
