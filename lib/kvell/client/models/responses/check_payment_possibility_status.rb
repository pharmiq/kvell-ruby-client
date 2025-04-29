# frozen_string_literal: true

module Kvell
  class Client
    module Models
      module Responses
        class CheckPaymentPossibilityStatus < Base
          property :error_message
          property :fio_nspk
          property :nspk_id
          property :status
        end
      end
    end
  end
end
