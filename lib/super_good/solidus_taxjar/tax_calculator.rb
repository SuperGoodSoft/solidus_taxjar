module SuperGood
  module SolidusTaxJar
    class TaxCalculator
      def self.default_api
        ::SuperGood::SolidusTaxJar::API.new
      end

      def initialize(order, api: self.class.default_api)
        @order = order
        @api = api
      end

      def calculate
        return no_tax if order.tax_address.empty?
        return no_tax unless taxjar_breakdown

        Spree::Tax::OrderTax.new(
          order_id: order.id,
          line_item_taxes: line_item_taxes,
          shipment_taxes: []
        )
      end

      private

      attr_reader :order, :api

      def line_item_taxes
        taxjar_breakdown.line_items.map do |line_item|
          Spree::Tax::ItemTax.new(
            item_id: line_item.id.to_i,
            label: "Sales Tax",
            tax_rate: tax_rate,
            amount: line_item.tax_collectable,
            included_in_price: false
          )
        end
      end

      def taxjar_breakdown
        @taxjar_breakdown ||= taxjar_tax.breakdown
      end

      def taxjar_tax
        @taxjar_taxes ||= api.tax_for(order)
      end

      def no_tax
        Spree::Tax::OrderTax.new(
          order_id: order.id,
          line_item_taxes: [],
          shipment_taxes: []
        )
      end

      def tax_rate
        Spree::TaxRate.find_by(name: "Sales Tax")
      end
    end
  end
end
