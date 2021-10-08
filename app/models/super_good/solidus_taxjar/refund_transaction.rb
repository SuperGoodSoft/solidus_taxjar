module SuperGood
  module SolidusTaxjar
    class RefundTransaction < ActiveRecord::Base
      belongs_to :order_transaction

      delegate :order, to: :order_transaction

      validates_presence_of :order_transaction
      validates_presence_of :transaction_id
      validates_presence_of :transaction_date
    end
  end
end
