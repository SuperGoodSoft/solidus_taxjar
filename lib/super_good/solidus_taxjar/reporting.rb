module SuperGood
  module SolidusTaxjar
    class Reporting
      def initialize(api: SuperGood::SolidusTaxjar.api)
        @api = api
      end

      def refund_and_create_new_transaction(order)
        @api.create_refund_transaction_for(order)
        @api.create_transaction_for(order)
      end

      def show_or_create_transaction(order)
        @api.show_latest_transaction_for(order) || @api.create_transaction_for(order)
      end
    end
  end
end
