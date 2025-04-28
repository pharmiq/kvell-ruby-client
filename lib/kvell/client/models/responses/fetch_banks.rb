# frozen_string_literal: true

module Kvell
  class Client
    module Models
      module Responses
        class FetchBanks < Base
          property :bank_id
          property :bank_bic
          property :name
        end
      end
    end
  end
end
