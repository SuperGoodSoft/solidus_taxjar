class SuperGood::SolidusTaxjar::TransactionSyncBatch < ApplicationRecord
  has_many :transaction_sync_logs
  has_many :orders, through: :transaction_sync_logs

  def status
    return 'processing' if transaction_sync_logs.processing.any?
    return 'error' if transaction_sync_logs.error.any?

    'success'
  end
end
