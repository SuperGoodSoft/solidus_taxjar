module SuperGood
  module SolidusTaxjar
    module Spree
      module ReportingSubscriber
        include ::Spree::Event::Subscriber
        include SolidusSupport::LegacyEventCompat::Subscriber
        include SuperGood::SolidusTaxjar::Reportable

        if ::Spree::Event.method_defined?(:register)
          ::Spree::Event.register("shipment_shipped")
        end

        event_action :report_transaction, event_name: :shipment_shipped
        event_action :replace_transaction, event_name: :order_recalculated

        def report_transaction(event)
          order = event.payload[:shipment].order

          with_reportable(order) do
            SuperGood::SolidusTaxjar::ReportTransactionJob.perform_later(order)
          end
        end

        def replace_transaction(event)
          order = event.payload[:order]

          with_reportable(order) do
            if transaction_replaceable?(order) && amount_changed?(order)
              SuperGood::SolidusTaxjar::ReplaceTransactionJob.perform_later(order)
            end
          end
        end

        private

        def amount_changed?(order)
          # We use `order.payment_total` to ensure we capture any total changes
          # from refunds.
          SuperGood::SolidusTaxjar.api.show_latest_transaction_for(order).amount !=
            (order.payment_total - order.additional_tax_total)
        end

        def transaction_replaceable?(order)
          order.taxjar_order_transactions.present? && order.payment_state == "paid"
        end
      end
    end
  end
end
