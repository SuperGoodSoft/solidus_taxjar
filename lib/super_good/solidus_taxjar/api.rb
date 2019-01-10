module SuperGood
  module SolidusTaxJar
    class API
      def self.default_taxjar_client
        ::Taxjar::Client.new(
          api_key: ENV.fetch("TAXJAR_API_KEY"),
          api_url: 'https://api.sandbox.taxjar.com'
        )
      end

      def initialize(taxjar_client: self.class.default_taxjar_client)
        @taxjar_client = taxjar_client
      end

      def tax_for(order)
        taxjar_client.tax_for_order order_params(order)
      end

      private

      attr_reader :taxjar_client

      def order_params(order)
        tax_address = order.tax_address

        {
          to_country: tax_address.country.iso,
          to_zip: tax_address.zipcode,
          to_city: tax_address.city,
          to_state: tax_address&.state&.abbr || tax_address.state_name,
          to_street: tax_address.address1,

          amount: order.item_total,
          shipping: order.shipment_total,

          line_items: order.line_items.map do |line_item|
            {
              id: line_item.id,
              quantity: line_item.quantity,
              unit_price: line_item.price,
              discount: -line_item.adjustment_total,
              product_tax_code: line_item.tax_category&.tax_code
            }
          end
        }
      end
    end
  end
end
