# frozen_string_literal: true

require_relative 'models/requests/base'

require_relative 'models/responses/base'
require_relative 'models/responses/fetch_banks'

module Kvell
  Requests = Client::Models::Requests
  Responses = Client::Models::Responses
end
