module SuperGood
  module SolidusTaxjar
    class TaxCalculator
      include CalculatorHelper

      def initialize(order, api: SuperGood::SolidusTaxjar.api)
        @order = order
        @api = api
      end

      def calculate
        return no_tax if SuperGood::SolidusTaxjar.test_mode
        return no_tax if incomplete_address?(order.tax_address) || order.line_items.none?
        return no_tax unless taxable_order? order
        return no_tax unless taxable_address? order.tax_address

        cache do
          next no_tax unless taxjar_breakdown

          Spree::Tax::OrderTax.new(
            order_id: order.id,
            line_item_taxes: line_item_taxes,
            shipment_taxes: shipment_taxes
          )
        end
      rescue => e
        exception_handler.call(e)
        no_tax
      end

      private

      attr_reader :order, :api

      def line_item_taxes
        @line_item_taxes ||=
          taxjar_breakdown.line_items.map { |taxjar_line_item|
            spree_line_item_id = taxjar_line_item.id.to_i

            # Searching in memory because this association is loaded and most
            # orders aren't going to have a huge number of line items.
            spree_line_item = order.line_items.find { |li| li.id == spree_line_item_id }

            Spree::Tax::ItemTax.new(
              item_id: spree_line_item_id,
              label: line_item_tax_label(taxjar_line_item, spree_line_item),
              tax_rate: tax_rate,
              amount: taxjar_line_item.tax_collectable,
              included_in_price: false
            )
          }
      end

      def shipment_taxes
        @shipment_taxes ||=
          if taxjar_breakdown.shipping? &&
              (total_shipping_tax = taxjar_breakdown.shipping.tax_collectable) != 0

            # Distribute shipping tax across shipments:
            # TaxJar does not provide a breakdown of shipping taxes, so we have
            # to proportionally distribute the tax across the shipments,
            # accounting for rounding errors.
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
                label: shipping_tax_label(shipment, shipping_tax),
                tax_rate: tax_rate,
                amount: shipping_tax,
                included_in_price: false
              )
            end

            tax_items << ::Spree::Tax::ItemTax.new(
              item_id: shipments.last.id,
              label: shipping_tax_label(shipments.last, remaining_tax),
              tax_rate: tax_rate,
              amount: remaining_tax,
              included_in_price: false
            )

            tax_items
          else
            []
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

      def cache_key
        SuperGood::SolidusTaxjar.cache_key.call(order)
      end

      def taxable_order?(order)
        SuperGood::SolidusTaxjar.taxable_order_check.call(order)
      end

      def shipping_tax_label(shipment, shipping_tax)
        SuperGood::SolidusTaxjar.shipping_tax_label_maker.call(
          shipment,
          shipping_tax
        )
      end

      def line_item_tax_label(taxjar_line_item, spree_line_item)
        SuperGood::SolidusTaxjar.line_item_tax_label_maker.call(taxjar_line_item, spree_line_item)
      end
    end
  end
end
