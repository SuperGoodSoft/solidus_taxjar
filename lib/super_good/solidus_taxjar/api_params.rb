module SuperGood
  module SolidusTaxjar
    module ApiParams
      class << self
        def order_params(order)
          {}
            .merge(customer_params(order))
            .merge(order_address_params(order.tax_address))
            .merge(line_items_params(order.line_items))
            .merge(shipping: shipping(order))
            .merge(SuperGood::SolidusTaxjar.custom_order_params.call(order))
            .tap do |params|
              next unless SuperGood::SolidusTaxjar.logging_enabled

              Rails.logger.info(
                "TaxJar params for #{order.number}: #{params.inspect}"
              )
            end
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

        def transaction_params(order)
          {}
            .merge(customer_params(order))
            .merge(order_address_params(order.tax_address))
            .merge(transaction_line_items_params(order.line_items))
            .merge(
              transaction_id: order.number,
              transaction_date: order.completed_at.to_formatted_s(:iso8601),
              amount: [order.total - order.additional_tax_total, 0].max,
              shipping: shipping(order),
              sales_tax: sales_tax(order)
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
            state: spree_address.state&.abbr || adddress.state_name,
            zip: spree_address.zipcode,
            city: spree_address.city,
            street: spree_address.address1
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

        def line_items_params(line_items)
          {
            line_items: valid_line_items(line_items).map do |line_item|
              {
                id: line_item.id,
                quantity: line_item.quantity,
                unit_price: line_item.price,
                discount: discount(line_item),
                product_tax_code: line_item.tax_category&.tax_code
              }
            end
          }
        end

        def transaction_line_items_params(line_items)
          {
            line_items: valid_line_items(line_items).map do |line_item|
              {
                id: line_item.id,
                quantity: line_item.quantity,
                product_identifier: line_item.sku,
                product_tax_code: line_item.tax_category&.tax_code,
                unit_price: line_item.price,
                discount: discount(line_item),
                sales_tax: line_item_sales_tax(line_item)
              }
            end
          }
        end

        def valid_line_items(line_items)
          # The API appears to error when sent line items with no quantity...
          # but why would you do that anyway.
          line_items.reject do |line_item|
            line_item.quantity.zero?
          end
        end

        def discount(line_item)
          ::SuperGood::SolidusTaxjar.discount_calculator.new(line_item).discount
        end

        def shipping(order)
          SuperGood::SolidusTaxjar.shipping_calculator.call(order)
        end

        def sales_tax(order)
          return 0 if order.total.zero?

          order.additional_tax_total
        end

        def line_item_sales_tax(line_item)
          return 0 if line_item.order.total.zero?

          line_item.additional_tax_total
        end
      end
    end
  end
end
