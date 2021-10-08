class AddTransactionDateToOrderTransaction < ActiveRecord::Migration[5.0]
  def change
    add_column :solidus_taxjar_order_transactions, :transaction_date, :datetime, null: false
  end
end
