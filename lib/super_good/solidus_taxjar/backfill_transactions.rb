module SuperGood
  module SolidusTaxjar
    class BackfillTransactions
      def initialize(api: SuperGood::SolidusTaxjar.api)
        @api = api
      end

      def call
        backfilled_orders = []
        ::Spree::Order.complete.where(shipment_state: 'shipped').find_each do |order|
          next if order.taxjar_order_transactions.any?
          api.create_transaction_for(order)
          backfilled_orders.push(order.number)
        end
        backfilled_orders
      end

      private

      attr_reader :api
    end
  end
end
