# frozen_string_literal: true

require 'test_helper'
require 'rack/test'
require_relative '../app'

class BSBWebServiceTest < Minitest::Test
  include Rack::Test::Methods

  def app
    BSBWebService
  end

  def setup
    # Set up test environment
    ENV['RACK_ENV'] = 'test'
    ENV['BSB_API_TOKENS'] = 'test-token-123'
  end

  def teardown
    # Clean up
    ENV.delete('BSB_API_TOKENS')
  end

  def test_health_endpoint_without_auth
    get '/health'
    assert_equal 200, last_response.status
    
    response = JSON.parse(last_response.body)
    assert response['status'] == 'ok'
    assert response['timestamp']
  end

  def test_docs_endpoint_without_auth
    get '/docs'
    assert_equal 200, last_response.status
    
    response = JSON.parse(last_response.body)
    assert response['title'] == 'BSB Web Service API'
    assert response['endpoints']
  end

  def test_bsb_lookup_without_auth
    get '/bsb/123456'
    assert_equal 401, last_response.status
    
    response = JSON.parse(last_response.body)
    assert_equal false, response['success']
    assert_includes response['error'], 'Authorization'
  end

  def test_bsb_lookup_with_invalid_token
    header 'Authorization', 'Bearer invalid-token'
    get '/bsb/123456'
    assert_equal 401, last_response.status
    
    response = JSON.parse(last_response.body)
    assert_equal false, response['success']
    assert_includes response['error'], 'Invalid or expired token'
  end

  def test_bsb_lookup_with_valid_token_invalid_format
    header 'Authorization', 'Bearer test-token-123'
    get '/bsb/invalid'
    assert_equal 400, last_response.status
    
    response = JSON.parse(last_response.body)
    assert_equal false, response['success']
    assert_includes response['error'], 'Invalid BSB number format'
  end

  def test_bsb_lookup_with_valid_token_not_found
    header 'Authorization', 'Bearer test-token-123'
    get '/bsb/999999'
    assert_equal 404, last_response.status
    
    response = JSON.parse(last_response.body)
    assert_equal false, response['success']
    assert_includes response['error'], 'BSB number not found'
  end

  def test_bsb_lookup_query_param_without_bsb
    header 'Authorization', 'Bearer test-token-123'
    get '/lookup'
    assert_equal 400, last_response.status
    
    response = JSON.parse(last_response.body)
    assert_equal false, response['success']
    assert_includes response['error'], 'Missing required parameter'
  end

  def test_bsb_lookup_query_param_with_valid_bsb
    header 'Authorization', 'Bearer test-token-123'
    get '/lookup?bsb=123456'
    
    # This will return 404 unless there's actual BSB data
    # In a real test, you'd mock the BSB.lookup method
    assert [404, 200].include?(last_response.status)
    
    response = JSON.parse(last_response.body)
    assert response.key?('success')
    assert response.key?('timestamp')
  end

  def test_rate_limiting
    header 'Authorization', 'Bearer test-token-123'
    
    # Make requests up to the limit
    101.times do |i|
      get '/bsb/123456'
      if i < 100
        assert_includes [200, 404], last_response.status
      else
        # The 101st request should be rate limited
        assert_equal 429, last_response.status
        response = JSON.parse(last_response.body)
        assert_equal false, response['success']
        assert_includes response['error'], 'Rate limit exceeded'
        break
      end
    end
  end

  def test_cors_headers
    header 'Authorization', 'Bearer test-token-123'
    get '/bsb/123456'
    
    assert last_response.headers['Access-Control-Allow-Origin']
  end

  def test_invalid_endpoint
    header 'Authorization', 'Bearer test-token-123'
    get '/invalid'
    assert_equal 404, last_response.status
    
    response = JSON.parse(last_response.body)
    assert_equal false, response['success']
    assert_includes response['error'], 'Endpoint not found'
  end

  def test_invalid_method
    header 'Authorization', 'Bearer test-token-123'
    post '/bsb/123456'
    assert_equal 405, last_response.status
    
    response = JSON.parse(last_response.body)
    assert_equal false, response['success']
    assert_includes response['error'], 'Method not allowed'
  end
end
