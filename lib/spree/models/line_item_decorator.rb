module Spree
  module LineItemDecorator
    protected

    def unit_price
      price
    end

    ::Spree::LineItem.prepend self
  end
end