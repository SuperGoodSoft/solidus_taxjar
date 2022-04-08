class CreateTransactionSyncLogs < ActiveRecord::Migration[5.0]
  def change
    create_table :solidus_taxjar_transaction_sync_logs do |t|
      t.references :transaction_sync_batch, foreign_key: {to_table: :solidus_taxjar_transaction_sync_batches}, index: {name: "index_transaction_sync_logs_on_transaction_sync_batch_id"}, null: false
      t.references :order, foreign_key: {to_table: :spree_orders}, null: false

      t.references :order_transaction, foreign_key: {to_table: :solidus_taxjar_order_transactions}, index: {name: "index_transaction_sync_logs_on_order_transaction_id"}
      t.integer :status, null: false, default: 0
      t.string :error_message

      t.timestamps
    end
  end
end
