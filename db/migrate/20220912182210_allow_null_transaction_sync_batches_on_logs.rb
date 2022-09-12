class AllowNullTransactionSyncBatchesOnLogs < ActiveRecord::Migration[6.1]
  def change
    change_column :solidus_taxjar_transaction_sync_logs, :transaction_sync_batch_id, :integer, null: true
  end
end
