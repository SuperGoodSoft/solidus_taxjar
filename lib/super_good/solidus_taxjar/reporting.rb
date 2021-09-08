module SuperGood
  module SolidusTaxjar
    class Reporting
      def initialize(api: SuperGood::SolidusTaxjar.api)
        @api = api
      end

      def report_transaction(order)
        begin
          @api.show_latest_transaction_for(order)
        rescue Taxjar::Error::NotFound
          @api.create_transaction_for(order)
        end
      end
    end
  end
end
