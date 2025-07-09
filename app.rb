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
    use WebService::RateLimiter
    
    # Authentication
    use WebService::Authentication
  end

  before do
    content_type :json
    headers 'Cache-Control' => 'no-cache, no-store, must-revalidate'
    headers 'Pragma' => 'no-cache'
    headers 'Expires' => '0'
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

  # BSB lookup via query parameter
  get '/lookup' do
    bsb_number = params[:bsb]
    
    unless bsb_number
      halt 400, error_response('Missing required parameter: bsb')
    end

    # Validate BSB number format
    unless bsb_number.match?(/^\d{3}-?\d{3}$/)
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

  # API documentation endpoint
  get '/docs' do
    {
      title: 'BSB Web Service API',
      version: BSB::VERSION,
      endpoints: {
        health: {
          method: 'GET',
          path: '/health',
          description: 'Check service health',
          authentication: false
        },
        bsb_lookup_path: {
          method: 'GET',
          path: '/bsb/{number}',
          description: 'Look up BSB details by number in path',
          authentication: true,
          parameters: {
            number: 'BSB number (6 digits, with or without dash)'
          }
        },
        bsb_lookup_query: {
          method: 'GET',
          path: '/lookup?bsb={number}',
          description: 'Look up BSB details by number in query parameter',
          authentication: true,
          parameters: {
            bsb: 'BSB number (6 digits, with or without dash)'
          }
        }
      },
      rate_limiting: {
        window: '1 minute',
        max_requests: 100
      },
      authentication: {
        type: 'Bearer Token',
        header: 'Authorization: Bearer {token}',
        description: 'Include your API token in the Authorization header'
      }
    }.to_json
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
