module SuperGood
  module SolidusTaxjar
    module Spree
      module ReportingSubscriber
        include ::Spree::Event::Subscriber
        include SolidusSupport::LegacyEventCompat::Subscriber

        ORDER_TOO_OLD_MESSAGE = "Order cannot be synced because it was completed before TaxJar reporting was enabled"

        if ::Spree::Event.method_defined?(:register)
          ::Spree::Event.register("shipment_shipped")
        end

        event_action :report_transaction, event_name: :shipment_shipped
        event_action :replace_transaction, event_name: :order_recalculated

        def report_transaction(event)
          return unless SuperGood::SolidusTaxjar.configuration.preferred_reporting_enabled

          order = event.payload[:shipment].order

          if completed_before_reporting_enabled?(order)
            order.taxjar_transaction_sync_logs.create!(status: :error, error_message: ORDER_TOO_OLD_MESSAGE)
            SuperGood::SolidusTaxjar.exception_handler.call(RuntimeError.new(ORDER_TOO_OLD_MESSAGE))
            return
          end

          SuperGood::SolidusTaxjar::ReportTransactionJob.perform_later(order)
        end

        def replace_transaction(event)
          return unless SuperGood::SolidusTaxjar.configuration.preferred_reporting_enabled

          order = event.payload[:order].reload

          return unless order.completed? && order.shipped?

          if completed_before_reporting_enabled?(order)
            order.taxjar_transaction_sync_logs.create!(status: :error, error_message: ORDER_TOO_OLD_MESSAGE)
            SuperGood::SolidusTaxjar.exception_handler.call(RuntimeError.new(ORDER_TOO_OLD_MESSAGE))
            return
          end

          if transaction_replaceable?(order) && amount_changed?(order)
            SuperGood::SolidusTaxjar::ReplaceTransactionJob.perform_later(order)
          end
        end

        private

        def amount_changed?(order)
          # We use `order.payment_total` to ensure we capture any total changes
          # from refunds.
          SuperGood::SolidusTaxjar.api.show_latest_transaction_for(order).amount !=
            (order.payment_total - order.additional_tax_total)
        end

        def completed_before_reporting_enabled?(order)
          configuration = SuperGood::SolidusTaxjar.configuration

          configuration.preferred_reporting_enabled &&
            configuration.preferred_reporting_enabled_at > order.completed_at
        end

        def transaction_replaceable?(order)
          order.taxjar_order_transactions.present? && order.payment_state == "paid"
        end
      end
    end
  end
end
