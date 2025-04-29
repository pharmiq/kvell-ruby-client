# frozen_string_literal: true

module Kvell
  module Configurable
    CONFIGURATION_OPTIONS = %i[
      api_endpoint
      api_key
      secret_key
      payout_secret_key
      logger
      open_timeout
      read_timeout
    ].freeze

    DEFAULTS_READ_TIMEOUT = 5
    DEFAULTS_OPEN_TIMEOUT = 2

    attr_accessor(*CONFIGURATION_OPTIONS)

    def configure
      yield self
      set_defaults
    end

    def set_defaults
      self.read_timeout ||= DEFAULTS_READ_TIMEOUT
      self.open_timeout ||= DEFAULTS_OPEN_TIMEOUT
      self.logger ||= Logger.new($stderr)
    end

    def options
      CONFIGURATION_OPTIONS.to_h { |attr| [attr, send(attr)] }
    end

    def same_options?(options)
      self.options.hash == options.hash
    end
  end
end
