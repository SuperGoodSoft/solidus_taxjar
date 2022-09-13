module SuperGood
  module SolidusTaxjar
    class BackfillTransactions
      def call(start_date:, end_date:)
        transaction_sync_batch = SuperGood::SolidusTaxjar::TransactionSyncBatch.create!(start_date: start_date, end_date: end_date)
        SuperGood::SolidusTaxjar::BackfillTransactionSyncBatchJob.perform_later(transaction_sync_batch)
        transaction_sync_batch
      end
    end
  end
end
