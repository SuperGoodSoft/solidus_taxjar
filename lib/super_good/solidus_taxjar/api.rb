module SuperGood
  module SolidusTaxjar
    class Api
      def self.default_taxjar_client
        client = ::Taxjar::Client.new(
          api_key: ENV["TAXJAR_API_KEY"],
          api_url: ENV.fetch("TAXJAR_API_URL") { "https://api.taxjar.com" } # Sandbox URL: https://api.sandbox.taxjar.com
        )
        client.set_api_config('headers', {
          'x-api-version' => '2020-08-07',
          'plugin' => 'supergoodsolidustaxjar'
        })
        client
      end

      def initialize(taxjar_client: self.class.default_taxjar_client)
        @taxjar_client = taxjar_client
      end

      def tax_for(order)
        taxjar_client.tax_for_order(ApiParams.order_params(order)).tap do |taxes|
          next unless SuperGood::SolidusTaxjar.logging_enabled

          Rails.logger.info(
            "TaxJar response for #{order.number}: #{taxes.to_h.inspect}"
          )
        end
      end

      def tax_rate_for(address)
        taxjar_client.tax_for_order(ApiParams.tax_rate_address_params(address)).rate
      end

      def tax_rates_for(address)
        taxjar_client.rates_for_location(*ApiParams.address_params(address))
      end

      def create_transaction_for(order)
        transaction_id = TransactionIdGenerator.next_transaction_id(order: order)
        response = taxjar_client.create_order(
          ApiParams.transaction_params(order, transaction_id)
        )
        order.taxjar_order_transactions.create!(
          transaction_id: response.transaction_id,
          transaction_date: response.transaction_date
        )
        response
      end

      def update_transaction_for(order)
        taxjar_client.update_order ApiParams.transaction_params(order)
      end

      def delete_transaction_for(order)
        taxjar_client.delete_order order.number
      end

      def show_latest_transaction_for(order)
        latest_transaction_id =
          OrderTransaction.latest_for(order)&.transaction_id

        if latest_transaction_id.nil?
          raise NotImplementedError,
            "No latest TaxJar order transaction for #{order.number}. "       \
            "Backfilling TaxJar transaction orders from Solidus is not yet " \
            "implemented."
        end

        taxjar_client.show_order(latest_transaction_id)
      end

      def create_refund_transaction_for(order)
        taxjar_order = show_latest_transaction_for(order)
        taxjar_client.create_refund ApiParams.refund_transaction_params(order, taxjar_order)
      end

      def create_refund_for(reimbursement)
        taxjar_client.create_refund ApiParams.refund_params(reimbursement)
      end

      def validate_spree_address(spree_address)
        taxjar_client.validate_address ApiParams.validate_address_params(spree_address)
      end

      def nexus_regions
        taxjar_client.nexus_regions
      end

      private

      attr_reader :taxjar_client
    end
  end
end
