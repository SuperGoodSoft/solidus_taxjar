module SuperGood
  module SolidusTaxjar
    class DiscountCalculator
      def initialize(line_item)
        @line_item = line_item
      end

      def discount
        -1 * line_item.adjustments.select { |value| !value.tax? && value.eligible? }.sum(&:amount)
      end

      private

      attr_reader :line_item
    end
  end
end
