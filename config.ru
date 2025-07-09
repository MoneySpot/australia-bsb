# frozen_string_literal: true

require_relative 'app'

# Configure Rack
use Rack::Deflater
use Rack::ConditionalGet
use Rack::ETag

run BSBWebService
