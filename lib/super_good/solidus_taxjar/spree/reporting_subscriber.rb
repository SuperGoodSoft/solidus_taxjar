module SuperGood
  module SolidusTaxjar
    module Spree
      class ReportingSubscriber
        include Omnes::Subscriber
        include SuperGood::SolidusTaxjar::Reportable

        # FIXME:
        # This is a workaround until we add a new Solidus event we can subscribe
        # to. "order_recalculated" occurs too early.
        #
        # This delay helps us be sure that `Spree::OrderUpdater#persist_totals`
        #  has been called, and the `order` transaction has been completed,
        #  before we report this transaction to TaxJar.
        #
        DELAY = 2

        handle :order_recalculated, with: :report_or_replace_transaction

        def report_or_replace_transaction(event)
          order = event.payload[:order]

          with_reportable(order) do
            SuperGood::SolidusTaxjar::ReportTransactionJob
              .set(wait: DELAY.seconds)
              .perform_later(order)

            return
          end

          with_replaceable(order) do
            SuperGood::SolidusTaxjar::ReplaceTransactionJob
              .set(wait: DELAY.seconds)
              .perform_later(order)
          end
        end
      end
    end
  end
end
