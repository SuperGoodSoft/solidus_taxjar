module SuperGood
  module SolidusTaxJar
    module APIParams
      class << self
        def order_params(order)
          {}
            .merge(order_address_params(order.tax_address))
            .merge(line_items_params(order.line_items))
            .merge(shipping: order.shipment_total)
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

        private

        def order_address_params(address)
          {
            to_country: address.country.iso,
            to_zip: address.zipcode,
            to_city: address.city,
            to_state: address&.state&.abbr || address.state_name,
            to_street: address.address1,
          }
        end

        def line_items_params(line_items)
          {
            line_items: line_items.map do |line_item|
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

        def discount(line_item)
          ::SuperGood::SolidusTaxJar.discount_calculator.new(line_item).discount
        end
      end
    end
  end
end
