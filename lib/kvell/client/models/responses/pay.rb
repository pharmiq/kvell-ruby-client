# frozen_string_literal: true

module Kvell
  class Client
    module Models
      module Responses
        class Error < Base
          property :code
          property :message
        end

        class Pay < Base
          property :id
          property :status
          property :transaction
          property :amount
          property :commission
          property :description
          property :created_at
          property :errors, coerce: [Error]
        end
      end
    end
  end
end
