# frozen_string_literal: true

module Kvell
  class Client
    module Models
      module Requests
        class Pay < Base
          property :amount, required: true
          property :phone, required: true
          property :bank_id, required: true
          property :fio, required: true
          property :transaction, required: true
          property :description, required: true
          property :customer
        end
      end
    end
  end
end
