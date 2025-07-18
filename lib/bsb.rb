# frozen_string_literal: true

require_relative 'bsb/version'
require 'json'
require_relative 'bsb_number_validator'

module BSB
  DB_FILEPATH = 'config/bsb_db.json'
  CHANGES_FILEPATH = 'config/latest_update.json'
  class << self
    def lookup(number)
      bsb = normalize(number)
      array = data_hash[bsb]
      return nil if array.nil?

      {
        bsb: bsb,
        mnemonic: array[0],
        bank_name: bank_name(bsb),
        branch: array[1],
        address: array[2],
        suburb: array[3],
        state: array[4],
        postcode: array[5],
        flags: {
          paper: (array[6][0] == 'P'),
          electronic: (array[6][1] == 'E'),
          high_value: (array[6][2] == 'H')
        }
      }
    end

    def bank_name(bsb)
      bank_list.each do |prefix, bank_name|
        return bank_name if bsb.start_with? prefix
      end
      nil
    end

    def normalize(str)
      str.gsub(/[^\d]/, '')
    end

    protected

    def data_hash
      @data_hash ||= begin
        file_path = File.expand_path("../#{DB_FILEPATH}", __dir__)
        JSON.parse(File.read(file_path))
      rescue JSON::ParserError => e
        warn "Error parsing BSB database: #{e.message}"
        {}
      rescue Errno::ENOENT => e
        warn "BSB database file not found: #{e.message}"
        {}
      end
    end

    def bank_list
      @bank_list ||= begin
        file_path = File.expand_path('../config/bsb_bank_list.json', __dir__)
        JSON.parse(File.read(file_path))
      rescue JSON::ParserError => e
        warn "Error parsing bank list: #{e.message}"
        {}
      rescue Errno::ENOENT => e
        warn "Bank list file not found: #{e.message}"
        {}
      end
    end
  end
end
