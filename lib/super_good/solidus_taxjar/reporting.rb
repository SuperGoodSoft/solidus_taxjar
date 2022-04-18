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
        transaction_response = @api.show_latest_transaction_for(order) || @api.create_transaction_for(order)
        SuperGood::SolidusTaxjar::OrderTransaction.find_by!(
          transaction_id: transaction_response.transaction_id
        )
      end
    end
  end
end
