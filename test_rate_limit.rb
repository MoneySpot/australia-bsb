#!/usr/bin/env ruby
# frozen_string_literal: true

require 'net/http'
require 'json'

# Configuration
HOST = 'localhost'
PORT = 4567
TOKEN = 'dev-token-123'
TEST_BSB = '123456'

puts "Rate Limiter Test for /bsb endpoint"
puts "=" * 40
puts "Host: #{HOST}:#{PORT}"
puts "Token: #{TOKEN}"
puts "Test BSB: #{TEST_BSB}"
puts "Expected limit: 100 requests/minute"
puts

def make_request(path, token)
  uri = URI("http://#{HOST}:#{PORT}#{path}")
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Get.new(uri)
  request['Authorization'] = "Bearer #{token}"
  
  response = http.request(request)
  {
    status: response.code.to_i,
    headers: response.to_hash,
    body: response.body
  }
rescue => e
  { error: e.message }
end

# Test the /bsb endpoint specifically
endpoint = "/bsb/#{TEST_BSB}"
successful_requests = 0
rate_limited_requests = 0
errors = 0

puts "Testing #{endpoint} endpoint..."
puts "Making 105 requests to test rate limiting..."

105.times do |i|
  response = make_request(endpoint, TOKEN)
  
  if response[:error]
    errors += 1
    if i < 5 || i > 100  # Show first few and last few errors
      puts "Request #{i + 1}: Error - #{response[:error]}"
    end
  elsif response[:status] == 200
    successful_requests += 1
  elsif response[:status] == 429
    rate_limited_requests += 1
    if rate_limited_requests == 1
      puts "Request #{i + 1}: Rate limited (429) - First rate limit hit!"
      # Show rate limit headers
      if response[:headers]['x-ratelimit-limit']
        puts "  Rate Limit Headers:"
        puts "    X-RateLimit-Limit: #{response[:headers]['x-ratelimit-limit']}"
        puts "    X-RateLimit-Window: #{response[:headers]['x-ratelimit-window']}"
        puts "    Retry-After: #{response[:headers]['retry-after']}"
      end
    elsif rate_limited_requests <= 5
      puts "Request #{i + 1}: Rate limited (429)"
    end
  else
    puts "Request #{i + 1}: Unexpected status #{response[:status]}"
  end
  
  # Show progress
  if (i + 1) % 20 == 0
    puts "Progress: #{i + 1}/105 requests completed"
  end
end

puts "\n" + "=" * 40
puts "Rate Limiter Test Results:"
puts "Successful requests (200): #{successful_requests}"
puts "Rate limited requests (429): #{rate_limited_requests}"
puts "Errors: #{errors}"
puts "Total: #{successful_requests + rate_limited_requests + errors}"

if successful_requests <= 100 && rate_limited_requests >= 5
  puts "✅ Rate limiter working correctly!"
  puts "   Expected ~100 successful, got #{successful_requests}"
  puts "   Expected ~5 rate limited, got #{rate_limited_requests}"
else
  puts "❌ Rate limiter issue detected!"
  puts "   Expected ~100 successful, got #{successful_requests}"
  puts "   Expected ~5 rate limited, got #{rate_limited_requests}"
end
