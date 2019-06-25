require 'spec_helper'

RSpec.describe SuperGood::SolidusTaxJar do
  it "has a version number" do
    expect(SuperGood::SolidusTaxJar::VERSION).not_to be nil
  end

  describe "configuration" do
    describe ".cache_key" do
      subject { described_class.cache_key.(order) }

      let(:order) { Spree::Order.new }

      it "returns the API params converted to JSON" do
        allow(SuperGood::SolidusTaxJar::APIParams)
          .to receive(:order_params)
          .with(order)
          .and_return({ some: "hash", with: "stuff", in: "it" })

        expect(subject).to eq '{"some":"hash","with":"stuff","in":"it"}'
      end
    end

    describe ".discount_calculator" do
      subject { described_class.discount_calculator }
      it { is_expected.to eq SuperGood::SolidusTaxJar::DiscountCalculator }
    end

    describe ".test_mode" do
      subject { described_class.test_mode }
      it { is_expected.to eq false }
    end

    describe ".exception_handler" do
      subject { described_class.exception_handler.(exception) }

      let(:exception) { StandardError.new("Something happened") }

      it "reports the exception using the Rails logger" do
        expect(Rails.logger).to receive(:error).with(
          "An error occurred while fetching TaxJar tax rates - Something happened: Something happened"
        )
        subject
      end
    end

    describe ".taxable_address_check" do
      subject { described_class.taxable_address_check.(address) }

      let(:address) { Spree::Address.new }

      it { is_expected.to eq true }
    end

    describe ".taxable_order_check" do
      subject { described_class.taxable_order_check.(order) }

      let(:order) { Spree::Order.new }

      it { is_expected.to eq true }
    end

    describe ".shipping_tax_label_maker" do
      subject { described_class.shipping_tax_label_maker.(shipment, shipping_tax) }
      let(:shipment) { Spree::Shipment.new }
      let(:shipping_tax) { BigDecimal("3.25") }
      it { is_expected.to eq "Sales Tax" }
    end

    describe ".line_item_tax_label_maker" do
      subject { described_class.line_item_tax_label_maker.(taxjar_line_item, spree_line_item) }
      let(:taxjar_line_item) { instance_double Taxjar::BreakdownLineItem }
      let(:spree_line_item) { Spree::LineItem.new }
      it { is_expected.to eq "Sales Tax" }
    end
  end
end
