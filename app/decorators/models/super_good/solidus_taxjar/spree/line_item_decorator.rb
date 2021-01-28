module SuperGood
  module SolidusTaxjar
    module Spree
      module LineItemDecorator
        def unit_price
          price
        end

        ::Spree::LineItem.prepend self
      end
    end
  end
end
