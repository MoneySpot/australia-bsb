# frozen_string_literal: true

module WebService
  class RateLimiter
    def initialize(app, options = {})
      @app = app
      @max_requests = options[:max_requests] || 100
      @window_seconds = options[:window_seconds] || 60
      @storage = {}
      @mutex = Mutex.new
    end

    def call(env)
      # Skip rate limiting for health check
      if env['PATH_INFO'] == '/health'
        return @app.call(env)
      end

      client_id = identify_client(env)
      
      if rate_limited?(client_id)
        return rate_limit_response
      end

      record_request(client_id)
      @app.call(env)
    end

    private

    def identify_client(env)
      # Use IP address and User-Agent as client identifier
      # In production, you might want to use authenticated user ID
      ip = env['HTTP_X_FORWARDED_FOR'] || env['HTTP_X_REAL_IP'] || env['REMOTE_ADDR'] || 'unknown'
      user_agent = env['HTTP_USER_AGENT'] || 'unknown'
      
      # Create a simple hash of IP and User-Agent for more specific identification
      "#{ip}:#{user_agent.hash}"
    end

    def rate_limited?(client_id)
      @mutex.synchronize do
        now = Time.now.to_i
        window_start = now - @window_seconds
        
        # Clean up old entries
        @storage[client_id] ||= []
        @storage[client_id].reject! { |timestamp| timestamp < window_start }
        
        # Check if limit exceeded
        @storage[client_id].size >= @max_requests
      end
    end

    def record_request(client_id)
      @mutex.synchronize do
        now = Time.now.to_i
        @storage[client_id] ||= []
        @storage[client_id] << now
      end
    end

    def rate_limit_response
      response_body = {
        success: false,
        error: 'Rate limit exceeded',
        details: {
          max_requests: @max_requests,
          window_seconds: @window_seconds,
          retry_after: @window_seconds
        },
        timestamp: Time.now.iso8601
      }.to_json

      [
        429,
        {
          'Content-Type' => 'application/json',
          'Retry-After' => @window_seconds.to_s,
          'X-RateLimit-Limit' => @max_requests.to_s,
          'X-RateLimit-Window' => @window_seconds.to_s,
          'Cache-Control' => 'no-cache, no-store, must-revalidate'
        },
        [response_body]
      ]
    end
  end
end
