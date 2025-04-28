# frozen_string_literal: true

require_relative 'client/models'

module Kvell
  class Client
    include Configurable

    FETCH_BANKS_PATH = '/v1/collections/banks'
    CHECK_PAYMENT_POSSIBILITY_PATH = '/v1/orders/payout/sbp/check'

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

    # @param [Kvell::Requests::CheckPaymentPossibility] params
    #
    # @return [Kvell::Responses::CheckPaymentPossibility]
    #
    def check_payment_possibility(params)
      headers = {
        'X-Api-Key' => api_key,
        'X-Signature' => signature_header(params.phone, params.bank_id),
      }
      response = http_post(
        CHECK_PAYMENT_POSSIBILITY_PATH,
        headers: headers,
        params: params,
      )

      Responses::CheckPaymentPossibility.new(JSON.parse(response.body))
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

    def signature_header(phone, bank_id)
      Digest::SHA256.hexdigest("#{api_key}#{phone}#{bank_id}#{secret_key}")
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
