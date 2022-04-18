module SuperGood
  module SolidusTaxjar
    class Reporting
      def initialize(api: SuperGood::SolidusTaxjar.api)
        @api = api
      end

      def report_transaction(order)
        begin
          transaction_response = @api.show_latest_transaction_for(order)
          SuperGood::SolidusTaxjar::OrderTransaction.find_by!(
            transaction_id: transaction_response.transaction_id
          )
        rescue NotImplementedError
          # FIXME:
          # We can stop rescuing from `NotImplementedError` once we have
          # fleshed out and implemented functionality to correctly backfill
          # TaxJar order transactions and
          # `SuperGood::SolidusTaxjar::OrderTransaction` records.
        rescue Taxjar::Error::NotFound
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
