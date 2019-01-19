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
          shipment_taxes: shipment_taxes
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

      def shipment_taxes
        @shipment_taxes ||=
          begin
            # Distribute shipping tax across shipments:
            # TaxJar does not provide a breakdown, so we have to proportionally
            # distribute the tax across the shipments, accounting for rounding
            # errors.
            total_shipping_tax = taxjar_tax.shipping

            tax_items = []
            remaining_tax = total_shipping_tax
            shipments = order.shipments.to_a
            total_shipping_cost = shipments.sum(&:total_before_tax)

            shipments[0...-1].each do |shipment|
              percentage_of_tax = shipment.total_before_tax / total_shipping_cost
              shipping_tax = (percentage_of_tax * total_shipping_tax).round(2)
              remaining_tax -= shipping_tax

              tax_items << ::Spree::Tax::ItemTax.new(
                item_id: shipment.id,
                label: "Sales Tax",
                tax_rate: tax_rate,
                amount: shipping_tax,
                included_in_price: false
              )
            end

            tax_items << ::Spree::Tax::ItemTax.new(
              item_id: shipments.last.id,
              label: "Sales Tax",
              tax_rate: tax_rate,
              amount: remaining_tax,
              included_in_price: false
            )

            tax_items
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
