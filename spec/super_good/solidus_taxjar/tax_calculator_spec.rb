require 'spec_helper'

RSpec.describe SuperGood::SolidusTaxJar::TaxCalculator do
  describe "#calculate" do
    subject { calculator.calculate }

    let(:calculator) { described_class.new(order) }

    let(:order) do
      Spree::Order.new(
        id: 10
      )
    end

    it "returns the taxes" do
      expect(subject.order_id).to eq order.id
      expect(subject.line_item_taxes).to be_empty
      expect(subject.shipment_taxes).to be_empty
    end
  end
end
