require "spec_helper"

RSpec.describe SuperGood::SolidusTaxjar::DiscountCalculator do
  describe "#discount" do
    subject { calculator.discount }

    let(:calculator) { described_class.new line_item }
    let(:line_item) { create :line_item }
    let!(:order) { create :completed_order_with_promotion, promotion: promotion_with_adjustment, line_items: [line_item] }

    let(:cancelation_adjustment_amount) { -8 }
    let(:promotion_adjustment_amount) { -2 }
    let(:promotion_with_adjustment) { create :promotion_with_item_adjustment, adjustment_rate: promotion_adjustment_amount }
    let!(:unit_cancellation_adjustment) { create :adjustment, order: order, adjustable: line_item, amount: cancelation_adjustment_amount, source_type: "Spree::UnitCancel" }

    let!(:tax_adjustment) { create :tax_adjustment, order: order, adjustable: line_item, amount: 2.50 }

    it "sums the total of all non-tax adjustments" do
      expect(subject).to eq(-1 * (cancelation_adjustment_amount + promotion_adjustment_amount))
    end

    context "a non-eligible adjustment exists" do
      let!(:unit_cancellation_adjustment) { create :adjustment, order: order, adjustable: line_item, eligible: false, amount: cancelation_adjustment_amount, source_type: "Spree::UnitCancel" }

      it "only sums eligible adjustments" do
        expect(subject).to eq(-1 * promotion_adjustment_amount)
      end
    end
  end
end
