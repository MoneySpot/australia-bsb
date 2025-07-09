# frozen_string_literal: true

module WebService
  module ErrorHandler
    def self.included(base)
      base.class_eval do
        # Handle JSON parsing errors
        error JSON::ParserError do
          status 400
          {
            success: false,
            error: 'Invalid JSON format',
            timestamp: Time.now.iso8601
          }.to_json
        end

        # Handle general errors
        error StandardError do |error|
          status 500
          
          # Log the error (in production, use proper logging)
          warn "Error: #{error.class}: #{error.message}"
          warn error.backtrace.join("\n") if ENV['RACK_ENV'] == 'development'
          
          {
            success: false,
            error: 'Internal server error',
            timestamp: Time.now.iso8601
          }.to_json
        end

        # Handle 404 errors
        not_found do
          {
            success: false,
            error: 'Endpoint not found',
            timestamp: Time.now.iso8601
          }.to_json
        end

        # Handle 405 errors (method not allowed)
        error 405 do
          {
            success: false,
            error: 'Method not allowed',
            timestamp: Time.now.iso8601
          }.to_json
        end
      end
    end
  end
end
