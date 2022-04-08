module SuperGood
  module SolidusTaxjar
    class BackfillTransactions
      def initialize(api: SuperGood::SolidusTaxjar.api)
        @api = api
      end

      def call
        backfilled_orders = []
        transaction_sync_batch = SuperGood::SolidusTaxjar::TransactionSyncBatch.create!

        ::Spree::Order.complete.where(shipment_state: 'shipped').find_each do |order|
          next if order.taxjar_order_transactions.any?
          transaction_sync_log = SuperGood::SolidusTaxjar::TransactionSyncLog.create!(
            transaction_sync_batch: transaction_sync_batch,
            order: order
          )
          begin
            order_transaction = SuperGood::SolidusTaxjar.reporting.show_or_create_transaction(order)
            transaction_sync_log.update!(order_transaction: order_transaction, status: :success)
          rescue Taxjar::Error => exception
            transaction_sync_log.update!(status: :error, error_message: exception.message)
          end
          backfilled_orders.push(order.number)
        end
        backfilled_orders
      end

      private

      attr_reader :api
    end
  end
end
