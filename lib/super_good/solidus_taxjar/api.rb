module SuperGood
  module SolidusTaxJar
    class API
      def self.default_taxjar_client
        ::Taxjar::Client.new(
          api_key: ENV.fetch("TAXJAR_API_KEY"),
          api_url: 'https://api.sandbox.taxjar.com'
        )
      end

      def initialize(taxjar_client: Client.default_taxjar_client)
        @taxjar_client = taxjar_client
      end

      def order_tax_for(order)
        taxjar_client.tax_for_order order_params(order)
      end

      private

      attr_reader :taxjar_client

      def order_params(order)
        ship_address = order.ship_address

        {
          to_country: ship_address.country.iso,
          to_zip: ship_address.zipcode,
          to_city: ship_address.city,
          to_state: ship_address&.state&.abbr || ship_address.state_name,
          to_street: ship_address.address1,

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
