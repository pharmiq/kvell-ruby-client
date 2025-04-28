# frozen_string_literal: true

require_relative 'models/requests/base'
require_relative 'models/requests/check_payment_possibility'
require_relative 'models/requests/pay'

require_relative 'models/responses/base'
require_relative 'models/responses/check_payment_possibility'
require_relative 'models/responses/fetch_banks'
require_relative 'models/responses/check_payment_possibility_status'
require_relative 'models/responses/pay'

module Kvell
  Requests = Client::Models::Requests
  Responses = Client::Models::Responses
end
