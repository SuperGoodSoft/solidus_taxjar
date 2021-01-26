require "spec_helper"

RSpec.describe SuperGood::SolidusTaxjar::DiscountCalculator do
  describe "#discount" do
    subject { calculator.discount }

    let(:calculator) { described_class.new line_item }

    let(:line_item) { ::Spree::LineItem.new(promo_total: 12.34) }

    it { is_expected.to eq(-12.34) }
  end
end
