module SuperGood
  module SolidusTaxJar
    class TaxCalculator
      def initialize(order)
        @order = order
      end

      def calculate
        Spree::Tax::OrderTax.new(
          order_id: order.id,
          line_item_taxes: line_item_rates,
          shipment_taxes: shipment_rates
        )
      end

      private

      attr_reader :order

      def line_item_rates
        []
      end

      def shipment_rates
        []
      end
    end
  end
end
