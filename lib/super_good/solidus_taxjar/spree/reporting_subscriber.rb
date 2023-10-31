module SuperGood
  module SolidusTaxjar
    module Spree
      class ReportingSubscriber
        include Omnes::Subscriber
        include SuperGood::SolidusTaxjar::Reportable

        handle :order_recalculated, with: :report_or_replace_transaction

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
