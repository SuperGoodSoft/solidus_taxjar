module SuperGood
  module SolidusTaxjar
    module Spree
      module ReportingSubscriber
        include ::Spree::Event::Subscriber

        if ::Spree::Event.method_defined?(:register)
          ::Spree::Event.register("shipment_shipped")
        end

        event_action :report_transaction, event_name: :shipment_shipped
        event_action :replace_transaction, event_name: :order_recalculated

        def report_transaction(event)
          return unless SuperGood::SolidusTaxjar.configuration.preferred_reporting_enabled

          SuperGood::SolidusTaxjar::ReportTransactionJob.perform_later(event.payload[:shipment].order)
        end

        def replace_transaction(event)
          order = event.payload[:order]

          return unless SuperGood::SolidusTaxjar.configuration.preferred_reporting_enabled
          return unless transaction_replaceable?(order)

          if order.complete? && order.paid? && amount_changed?(order)
            SuperGood::SolidusTaxjar::ReplaceTransactionJob.perform_later(event.payload[:order])
          end
        end

        private

        def amount_changed?(order)
          SuperGood::SolidusTaxjar.api.show_latest_transaction_for(order).amount !=
            (order.total - order.additional_tax_total)
        end

        def transaction_replaceable?(order)
          order.taxjar_order_transactions.present?
        end
      end
    end
  end
end
