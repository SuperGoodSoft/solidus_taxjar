class CreateTransactionSyncBatches < ActiveRecord::Migration[5.0]
  def change
    create_table :solidus_taxjar_transaction_sync_batches do |t|
      t.timestamps
    end
  end
end
