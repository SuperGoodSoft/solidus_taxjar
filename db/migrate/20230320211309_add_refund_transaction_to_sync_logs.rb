class AddRefundTransactionToSyncLogs < ActiveRecord::Migration[6.1]
  def change
    add_reference :solidus_taxjar_transaction_sync_logs, :refund_transaction, foreign_key: {to_table: :solidus_taxjar_refund_transactions}, index: {name: "index_transaction_sync_logs_on_refund_transaction_id"}
  end
end
