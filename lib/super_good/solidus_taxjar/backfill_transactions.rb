module SuperGood
  module SolidusTaxjar
    class BackfillTransactions
      def call
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
        end

        transaction_sync_batch
      end
    end
  end
end
