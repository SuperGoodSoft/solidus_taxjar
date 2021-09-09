class CreateTaxjarOrderTransactions < ActiveRecord::Migration[5.0]
  def change
    create_table :solidus_taxjar_order_transactions do |t|
      t.references :order, null: false
      t.string :transaction_id, null: false

      t.timestamps
    end

    add_foreign_key :solidus_taxjar_order_transactions,
      :spree_orders,
      column: :order_id

    add_index :solidus_taxjar_order_transactions, :transaction_id, unique: true
  end
end
