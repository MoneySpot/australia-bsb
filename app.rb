# frozen_string_literal: true

require 'sinatra/base'
require 'json'
require 'dotenv/load'
require 'rack/cors'
require_relative 'lib/bsb'
require_relative 'lib/web_service/rate_limiter'
require_relative 'lib/web_service/authentication'
require_relative 'lib/web_service/error_handler'

class BSBWebService < Sinatra::Base
  include WebService::ErrorHandler
  
  configure do
    set :environment, ENV['RACK_ENV'] || 'development'
    set :port, ENV['PORT'] || 4567
    set :bind, ENV['HOST'] || 'localhost'
    
    # Enable CORS
    use Rack::Cors do
      allow do
        origins '*'
        resource '*', headers: :any, methods: [:get, :options]
      end
    end
    
    # Rate limiting
    rate_limit_options = {}
    if ENV['RACK_ENV'] == 'test'
      rate_limit_options = { max_requests: 1000, window_seconds: 60 }
    end
    use WebService::RateLimiter, rate_limit_options
    
    # Authentication
    use WebService::Authentication
  end

  before do
    content_type :json
    headers 'Cache-Control' => 'no-cache, no-store, must-revalidate'
    headers 'Pragma' => 'no-cache'
    headers 'Expires' => '0'
    headers 'Access-Control-Allow-Origin' => '*'
    headers 'Access-Control-Allow-Methods' => 'GET, OPTIONS'
    headers 'Access-Control-Allow-Headers' => 'Content-Type, Authorization'
  end

  # Health check endpoint
  get '/health' do
    { status: 'ok', timestamp: Time.now.iso8601 }.to_json
  end

  # BSB lookup endpoint
  get '/bsb/:number' do
    bsb_number = params[:number]
    
    # Validate BSB number format
    unless bsb_number&.match?(/^\d{3}-?\d{3}$/)
      halt 400, error_response('Invalid BSB number format. Expected format: 123456 or 123-456')
    end

    # Normalize and lookup BSB
    result = BSB.lookup(bsb_number)
    
    if result
      success_response(result)
    else
      halt 404, error_response('BSB number not found')
    end
  end

  # Handle unsupported methods on BSB endpoint
  [:post, :put, :patch, :delete].each do |method|
    send(method, '/bsb/:number') do
      halt 405, error_response('Method not allowed')
    end
  end

  private

  def success_response(data)
    {
      success: true,
      data: data,
      timestamp: Time.now.iso8601
    }.to_json
  end

  def error_response(message)
    {
      success: false,
      error: message,
      timestamp: Time.now.iso8601
    }.to_json
  end

  # Start the server if this file is executed directly
  run! if app_file == $0
end
