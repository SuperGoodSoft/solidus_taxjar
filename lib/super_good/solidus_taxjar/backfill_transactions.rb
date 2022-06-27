module SuperGood
  module SolidusTaxjar
    class BackfillTransactions
      def call
        transaction_sync_batch = SuperGood::SolidusTaxjar::TransactionSyncBatch.create!
        SuperGood::SolidusTaxjar::BackfillTransactionSyncBatchJob.perform_later(transaction_sync_batch)
        transaction_sync_batch
      end
    end
  end
end
