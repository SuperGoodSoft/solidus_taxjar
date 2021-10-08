module SuperGood
  module SolidusTaxjar
    class OrderTransaction < ActiveRecord::Base
      belongs_to :order, class_name: "Spree::Order"

      validates_presence_of :transaction_id
      validates_presence_of :transaction_date
    end
  end
end
