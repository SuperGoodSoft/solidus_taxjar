class CreateTaxjarRefundTransaction < ActiveRecord::Migration[5.0]
  def change
    create_table :solidus_taxjar_refund_transactions do |t|
      t.references :order_transaction, index: { unique: true, name: :refund_transactions_orders_idx }
      t.string :transaction_id, null: false, index: { unique: true }
      t.datetime :transaction_date, null: false

      t.timestamps
    end

    add_foreign_key :solidus_taxjar_refund_transactions,
      :solidus_taxjar_order_transactions,
      column: :order_transaction_id
  end
end
