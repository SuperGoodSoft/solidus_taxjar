module SuperGood
  module SolidusTaxjar
    module Spree
      class ReportingSubscriber
        include Omnes::Subscriber
        include SuperGood::SolidusTaxjar::Reportable

        handle :shipment_shipped, with: :report_transaction
        handle :order_recalculated, with: :replace_transaction

        def report_transaction(event)
          order = event.payload[:shipment].order

          with_reportable(order) do
            SuperGood::SolidusTaxjar::ReportTransactionJob.perform_later(order)
          end
        end

        def replace_transaction(event)
          order = event.payload[:order]

          with_replaceable(order) do
            SuperGood::SolidusTaxjar::ReplaceTransactionJob.perform_later(order)
          end
        end
      end
    end
  end
end
