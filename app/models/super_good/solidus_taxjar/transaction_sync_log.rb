class SuperGood::SolidusTaxjar::TransactionSyncLog < ApplicationRecord
  belongs_to :transaction_sync_batch, optional: true
  belongs_to :order, class_name: "Spree::Order"
  belongs_to :order_transaction, optional: true

  enum status: [:processing, :success, :error]
end
