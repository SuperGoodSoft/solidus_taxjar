module SuperGood
  module SolidusTaxjar
    class DiscountCalculator
      def initialize(line_item)
        @line_item = line_item
      end

      def discount
        -line_item.promo_total
      end

      private

      attr_reader :line_item
    end
  end
end
