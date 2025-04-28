# frozen_string_literal: true

require_relative 'client/models'

module Kvell
  class Client
    include Configurable

    FETCH_BANKS_PATH = '/v1/collections/banks'

    def initialize(options = {})
      CONFIGURATION_OPTIONS.each do |attribute|
        value = options[attribute] || Kvell.send(attribute)
        send("#{attribute}=", value)
      end
      connection
    end

    # @return [Array<Kvell::Responses::Bank>]
    #
    def fetch_banks
      response = http_get(FETCH_BANKS_PATH, headers: { 'X-Api-Key' => api_key })

      JSON.parse(response.body).map do |bank_data|
        Responses::FetchBanks.new(bank_data)
      end
    end

    # @param [Hash] params
    #
    # @return [Kvell::Responses::CheckPaymentPossibility]
    #
    def check_payment_possibility(**params)
      response = http_post(CHECK_PAYMENT_POSSIBILITY_PATH, headers: { 'X-Api-Key' => api_key }, params: params)

      JSON.parse(response.body)
    end

    private

    def connection
      @connection ||= Faraday.new(url: api_endpoint) do |connection|
        setup_timeouts!(connection)
        setup_error_handling!(connection)
        setup_log_filters!(connection)
        setup_headers!(connection)

        connection.adapter(Faraday.default_adapter)
      end
    end

    def setup_timeouts!(connection)
      connection.options.open_timeout = open_timeout
      connection.options.timeout = read_timeout
    end

    def setup_error_handling!(connection)
      connection.response(:raise_error)
    end

    def setup_log_filters!(connection)
      options = { headers: true, bodies: true, log_level: :debug }
      connection.response(:logger, logger, options) do |logger|
        logger.filter(/(X-Api-Key: )([^&]+)/, '\1[FILTERED]')
      end
    end

    def setup_headers!(connection)
      connection.headers['Content-Type'] = 'application/json'
    end

    def http_post(resource, params:, headers: {})
      connection.post do |request|
        request.url(resource)
        request.headers.merge!(headers)
        request.body = params.to_json
      end
    end

    def http_get(resource, params: {}, headers: {})
      connection.get do |request|
        request.url(resource)
        request.headers.merge!(headers)
        request.params = params
      end
    end
  end
end
