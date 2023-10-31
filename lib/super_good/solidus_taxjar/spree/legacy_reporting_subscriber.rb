module SuperGood
  module SolidusTaxjar
    module Spree
      module LegacyReportingSubscriber
        include ::Spree::Event::Subscriber
        include SolidusSupport::LegacyEventCompat::Subscriber
        include SuperGood::SolidusTaxjar::Reportable

        if ::Spree::Event.method_defined?(:register)
          ::Spree::Event.register("shipment_shipped")
        end

        event_action :report_or_replace_transaction, event_name: :order_recalculated

        def report_or_replace_transaction(event)
          order = event.payload[:order]

          with_reportable(order) do
            SuperGood::SolidusTaxjar::ReportTransactionJob.perform_later(order)
            return
          end

          with_replaceable(order) do
            SuperGood::SolidusTaxjar::ReplaceTransactionJob.perform_later(order)
          end
        end
      end
    end
  end
end
