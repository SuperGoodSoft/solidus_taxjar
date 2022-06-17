module SuperGood
  module SolidusTaxjar
    class Reporting
      def initialize(api: SuperGood::SolidusTaxjar.api)
        @api = api
      end

      def refund_and_create_new_transaction(order)
        latest_order_transaction = OrderTransaction.latest_for(order)
        unless latest_order_transaction.refund_transaction
          transaction_response = @api.create_refund_transaction_for(order)
          latest_order_transaction.create_refund_transaction!(
            transaction_id: transaction_response.transaction_id,
            transaction_date: transaction_response.transaction_date
          )
        end
        if transaction_response = @api.create_transaction_for(order)
          order.taxjar_order_transactions.create!(
            transaction_id: transaction_response.transaction_id,
            transaction_date: transaction_response.transaction_date
          )
        end
      end

      def show_or_create_transaction(order)
        if transaction_response = @api.show_latest_transaction_for(order)
          SuperGood::SolidusTaxjar::OrderTransaction.find_by!(
            transaction_id: transaction_response.transaction_id
          )
        else
          transaction_response = @api.create_transaction_for(order)
          order.taxjar_order_transactions.create!(
            transaction_id: transaction_response.transaction_id,
            transaction_date: transaction_response.transaction_date
          )
        end
      end
    end
  end
end
