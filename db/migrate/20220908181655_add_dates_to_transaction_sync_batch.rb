class AddDatesToTransactionSyncBatch < ActiveRecord::Migration[6.1]
  def change
    add_column :solidus_taxjar_transaction_sync_batches, :start_date, :date
    add_column :solidus_taxjar_transaction_sync_batches, :end_date, :date
  end
end
