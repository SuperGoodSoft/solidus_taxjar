require 'spec_helper'

RSpec.describe SuperGood::SolidusTaxJar do
  it "has a version number" do
    expect(SuperGood::SolidusTaxJar::VERSION).not_to be nil
  end

  describe "configuration" do
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
  end
end
