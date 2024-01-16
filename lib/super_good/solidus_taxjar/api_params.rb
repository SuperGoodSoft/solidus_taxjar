module SuperGood
  module SolidusTaxjar
    module ApiParams
      UNTAXABLE_INVENTORY_UNIT_STATES = ["returned", "canceled"]

      class << self
        def order_params(order)
          {}
            .merge(customer_params(order))
            .merge(order_address_params(order.tax_address))
            .merge(line_items_params(order.line_items))
            .merge(shipping: shipping(order))
            .merge(SuperGood::SolidusTaxjar.custom_order_params.call(order))
        end

        def address_params(address)
          [
            address.zipcode,
            {
              street: address.address1,
              city: address.city,
              state: address&.state&.abbr || address.state_name,
              country: address.country.iso
            }
          ]
        end

        def tax_rate_address_params(address)
          {
            amount: 100,
            shipping: 0
          }.merge(order_address_params(address))
        end

        def transaction_params(order, transaction_id = order.number)
          {}
            .merge(customer_params(order))
            .merge(order_address_params(order.tax_address))
            .merge(transaction_line_items_params(order.line_items))
            .merge(
              transaction_id: transaction_id,
              transaction_date: order.completed_at.to_formatted_s(:iso8601),
              # We use `payment_total` to reflect the total liablity
              # transferred.
              amount: [order.payments.completed.sum(&:amount) - refund_total_without_tax(order) - order.additional_tax_total, 0].max,
              shipping: shipping(order),
              sales_tax: sales_tax(order)
            )
        end

        def refund_transaction_params(spree_order, taxjar_order)
          {}
            .merge(order_address_params(spree_order.tax_address))
            .merge(
              {
                transaction_id: TransactionIdGenerator.refund_transaction_id(taxjar_order.transaction_id),
                transaction_reference_id: taxjar_order.transaction_id,
                transaction_date: spree_order.completed_at.to_formatted_s(:iso8601),
                amount: -1 * taxjar_order.amount,
                sales_tax: -1 * taxjar_order.sales_tax,
                shipping: -1 * taxjar_order.shipping,
                line_items: taxjar_order.line_items.map { |line_item|
                  line_item.to_h.merge({
                    unit_price: line_item.unit_price * -1,
                    discount:  line_item.discount * -1,
                    sales_tax: line_item.sales_tax * -1
                  })
                }
              }
            )
        end

        def refund_params(reimbursement)
          additional_taxes = reimbursement.return_items.sum(&:additional_tax_total)

          {}
            .merge(order_address_params(reimbursement.order.tax_address))
            .merge(
              transaction_id: reimbursement.number,
              transaction_reference_id: reimbursement.order.number,
              transaction_date: reimbursement.order.completed_at.to_formatted_s(:iso8601),
              amount: reimbursement.total - additional_taxes,
              shipping: 0,
              sales_tax: additional_taxes
            )
        end

        def validate_address_params(spree_address)
          {
            country: spree_address.country&.iso,
            state: spree_address.state&.abbr || spree_address.state_name,
            zip: spree_address.zipcode,
            city: spree_address.city,
            street: [spree_address.address1, spree_address.address2].compact.join(' ')
          }
        end

        private

        def customer_params(order)
          return {} unless order.user_id

          {customer_id: order.user_id.to_s}
        end

        def order_address_params(address)
          {
            to_country: address.country.iso,
            to_zip: address.zipcode,
            to_city: address.city,
            to_state: address&.state&.abbr || address.state_name,
            to_street: address.address1
          }
        end

        # @private
        # This method builds line item parameters as expected by the TaxJar
        # Tax API.
        #
        # @param line_items [Spree::LineItem::ActiveRecord_Relation] All of the
        #   order's line items.
        # @return [Hash] A TaxJar API-friendly line item collection.
        def line_items_params(line_items)
          {
            line_items: line_items.filter_map { |line_item|
              next unless line_item.quantity.positive?

              {
                id: line_item.id,
                quantity: line_item.quantity,
                unit_price: line_item.price,
                discount: discount(line_item),
                product_tax_code: line_item.tax_category&.tax_code
              }
            }
          }
        end

        # @private
        # This method builds line item parameters as expected by the TaxJar
        # Transactions API. Note that this logic different from
        # `.line_item_params` as it excludes inventory units we consider to be
        # untaxable (i.e. returned or cancelled inventory units).
        #
        # @param line_items [Spree::LineItem::ActiveRecord_Relation] All of the
        #   order's line items.
        # @return [Hash] A TaxJar API-friendly line item collection.
        def transaction_line_items_params(line_items)
          {
            line_items: line_items.filter_map { |line_item|
              quantity = taxable_quantity line_item
              next unless quantity.positive?

              {
                id: line_item.id,
                quantity: quantity,
                product_identifier: line_item.sku,
                description: line_item.variant.descriptive_name,
                product_tax_code: line_item.tax_category&.tax_code,
                unit_price: line_item.price,
                discount: discount(line_item),
                sales_tax: line_item_sales_tax(line_item)
              }
            }
          }
        end

        def discount(line_item)
          ::SuperGood::SolidusTaxjar.discount_calculator.new(line_item).discount
        end

        def shipping(order)
          SuperGood::SolidusTaxjar.shipping_calculator.call(order)
        end

        def sales_tax(order)
          return 0 if order.total.zero?

          order.additional_tax_total - order_reimbursement_tax_total(order)
        end

        def line_item_sales_tax(line_item)
          return 0 if line_item.order.total.zero?

          line_item.additional_tax_total -  line_item_reimbursement_tax_total(line_item)
        end

        def taxable_quantity(line_item)
          line_item.inventory_units
            .where.not(state: UNTAXABLE_INVENTORY_UNIT_STATES)
            .count
        end

        def line_item_reimbursement_tax_total(line_item)
          line_item
            .inventory_units
            .flat_map(&:return_items)
            .filter { |return_item| return_item.reimbursement.present? }
            .sum(&:additional_tax_total)
        end

        def order_reimbursement_tax_total(order)
          order.reimbursements.sum { |reimbursement| reimbursement_tax_total(reimbursement) }
        end

        def reimbursement_tax_total(reimbursement)
          reimbursement.return_items.sum(&:additional_tax_total)
        end

        def refund_total_without_tax(order)
          order.refunds.sum do |refund|
            if refund.reimbursement.present?
              refund.reimbursement.total - reimbursement_tax_total(refund.reimbursement)
            else
              # This use case represents making a line item level adjustment, and then refunding
              # that amount.
              refund.amount
            end
          end
        end
      end
    end
  end
end
