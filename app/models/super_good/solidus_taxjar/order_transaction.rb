module SuperGood
  module SolidusTaxjar
    class OrderTransaction < ActiveRecord::Base
      belongs_to :order, class_name: "Spree::Order"

      validates_presence_of :transaction_id
      validates_presence_of :transaction_date

      def self.latest_for(order)
        where(order: order).order(transaction_date: :desc).limit(1).first
      end
    end
  end
end
