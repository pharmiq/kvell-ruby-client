# frozen_string_literal: true

require_relative 'client/models'

module Kvell
  class Client
    include Configurable

    FETCH_BANKS_PATH = '/v1/collections/banks'
    CHECK_PAYMENT_POSSIBILITY_PATH = '/v1/orders/payout/sbp/check'
    CHECK_PAYMENT_POSSIBILITY_STATUS_PATH = '/v1/orders/payout/sbp/check/status'
    PAY_PATH = '/v1/orders/payout/sbp'

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

    # @param params [Kvell::Requests::CheckPaymentPossibility] params
    #
    # @return [Kvell::Responses::CheckPaymentPossibility]
    #
    def check_payment_possibility(params)
      headers = {
        'X-Api-Key' => api_key,
        'X-Signature' => signature_header(params.slice(:phone, :bank_id)),
      }
      response = http_post(
        CHECK_PAYMENT_POSSIBILITY_PATH,
        headers: headers,
        params: params,
      )

      Responses::CheckPaymentPossibility.new(JSON.parse(response.body))
    end

    # @param request_id [String]
    #
    # @return [Kvell::Responses::CheckPaymentPossibilityStatus]
    #
    def check_payment_possibility_status(request_id)
      headers = {
        'X-Api-Key' => api_key,
        'X-Signature' => signature_header({ request_id: request_id }),
      }
      response = http_get(
        "#{CHECK_PAYMENT_POSSIBILITY_STATUS_PATH}/#{request_id}",
        headers: headers,
      )

      Responses::CheckPaymentPossibilityStatus.new(JSON.parse(response.body))
    end

    # @param params [Kvell::Requests::Pay]
    #
    # @return [Kvell::Responses::Pay]
    #
    def pay(params)
      headers = {
        'X-Api-Key' => api_key,
        'X-Signature' => payment_signature_header(params),
      }
      response = http_post(PAY_PATH, headers: headers, params: params)

      Responses::Pay.new(JSON.parse(response.body))
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

    def signature_header(data)
      Digest::SHA256.hexdigest("#{api_key}#{data.values.join}#{secret_key}")
    end

    def payment_signature_header(data)
      Digest::SHA256.hexdigest("#{api_key}#{data.to_json}#{payout_secret_key}")
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
