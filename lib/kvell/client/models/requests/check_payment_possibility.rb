# frozen_string_literal: true

module Kvell
  class Client
    module Models
      module Requests
        class CheckPaymentPossibility < Base
          property :amount, required: true
          property :phone, required: true
          property :bank_id, required: true
          property :fio, required: true
          property :fio_check, required: true
        end
      end
    end
  end
end
