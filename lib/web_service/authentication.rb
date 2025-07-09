# frozen_string_literal: true

module WebService
  class Authentication
    def initialize(app)
      @app = app
      @valid_tokens = load_valid_tokens
    end

    def call(env)
      request = Rack::Request.new(env)
      
      # Skip authentication for health check and docs
      if public_endpoints.include?(request.path_info)
        return @app.call(env)
      end

      # Check for Authorization header
      auth_header = env['HTTP_AUTHORIZATION']
      
      unless auth_header
        return unauthorized_response('Missing Authorization header')
      end

      # Extract token from Bearer format
      token = extract_token(auth_header)
      
      unless token
        return unauthorized_response('Invalid Authorization header format. Expected: Bearer <token>')
      end

      # Validate token
      unless valid_token?(token)
        return unauthorized_response('Invalid or expired token')
      end

      # Store token info in env for potential use in application
      env['bsb.auth.token'] = token
      env['bsb.auth.authenticated'] = true

      @app.call(env)
    end

    private

    def public_endpoints
      ['/health']
    end

    def load_valid_tokens
      # In production, this should load from a secure storage
      # For now, we'll use environment variables and a simple token list
      tokens = ENV['BSB_API_TOKENS']&.split(',') || []
      
      # Add default development token if in development
      if ENV['RACK_ENV'] == 'development' || ENV['RACK_ENV'].nil?
        tokens << 'dev-token-123'
      end
      
      tokens.map(&:strip).reject(&:empty?)
    end

    def extract_token(auth_header)
      match = auth_header.match(/^Bearer\s+(.+)$/i)
      match&.captures&.first
    end

    def valid_token?(token)
      @valid_tokens.include?(token)
    end

    def unauthorized_response(message)
      response_body = {
        success: false,
        error: message,
        timestamp: Time.now.iso8601
      }.to_json

      [
        401,
        {
          'Content-Type' => 'application/json',
          'Cache-Control' => 'no-cache, no-store, must-revalidate'
        },
        [response_body]
      ]
    end
  end
end
