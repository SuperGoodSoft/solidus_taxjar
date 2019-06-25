module SuperGood
  module SolidusTaxJar
    class API
      def self.default_taxjar_client
        ::Taxjar::Client.new(
          api_key: ENV.fetch("TAXJAR_API_KEY"),
          api_url: ENV.fetch("TAXJAR_API_URL") { 'https://api.taxjar.com' } # Sandbox URL: https://api.sandbox.taxjar.com
        )
      end

      def initialize(taxjar_client: self.class.default_taxjar_client)
        @taxjar_client = taxjar_client
      end

      def tax_for(order)
        taxjar_client.tax_for_order(APIParams.order_params(order)).tap do |taxes|
          next unless SuperGood::SolidusTaxJar.logging_enabled

          Rails.logger.info(
            "TaxJar response for #{order.number}: #{taxes.to_h.inspect}"
          )
        end
      end

      def tax_rates_for(address)
        taxjar_client.rates_for_location(*APIParams.address_params(address))
      end

      def create_transaction_for(order)
        taxjar_client.create_order APIParams.transaction_params(order)
      end

      def update_transaction_for(order)
        taxjar_client.update_order APIParams.transaction_params(order)
      end

      def delete_transaction_for(order)
        taxjar_client.delete_order order.number
      end

      def create_refund_for(reimbursement)
        taxjar_client.create_refund APIParams.refund_params(reimbursement)
      end

      private

      attr_reader :taxjar_client
    end
  end
end
