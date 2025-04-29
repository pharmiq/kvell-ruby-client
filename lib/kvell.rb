# frozen_string_literal: true

require 'faraday'
require 'hashie'

require_relative 'kvell/version'
require_relative 'kvell/configurable'
require_relative 'kvell/client'

module Kvell
  class << self
    include Configurable

    def client
      return @client if defined?(@client) && @client.same_options?(options)

      @client = Client.new(options)
    end
  end
end
