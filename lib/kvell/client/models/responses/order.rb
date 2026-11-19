# frozen_string_literal: true

module Kvell
  class Client
    module Models
      module Responses
        # Состояние операции (выплаты) в Kvell: GET /v1/orders/{transaction}.
        #
        # status:
        #   new, processing — операция ещё обрабатывается, итог неизвестен;
        #   completed       — выполнена;
        #   canceled        — отклонена, причина в error_code и error_message.
        class Order < Base
          IN_PROGRESS_STATUSES = %w[new processing].freeze
          COMPLETED_STATUS = 'completed'
          CANCELED_STATUS = 'canceled'

          property :id
          property :status
          property :transaction
          property :amount
          property :commission
          property :description
          property :ecommerce_type
          property :error_code
          property :error_message
          property :created_at

          def in_progress?
            IN_PROGRESS_STATUSES.include?(status)
          end

          def completed?
            status == COMPLETED_STATUS
          end

          def canceled?
            status == CANCELED_STATUS
          end
        end
      end
    end
  end
end
