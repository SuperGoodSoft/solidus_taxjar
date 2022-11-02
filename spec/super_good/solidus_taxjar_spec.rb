require "spec_helper"

RSpec.describe SuperGood::SolidusTaxjar do
  it "has a version number" do
    expect(SuperGood::SolidusTaxjar::VERSION).not_to be nil
  end

  describe ".table_name_prefix" do
    subject { described_class.table_name_prefix }

    it { is_expected.to eq("solidus_taxjar_") }
  end

  describe ".api" do
    subject { described_class.api }

    it "returns an instance of the api client" do
      expect(subject).to be_a(SuperGood::SolidusTaxjar::Api)
    end
  end

  describe ".reporting" do
    subject { described_class.reporting }

    it "creates a new reporting" do
      expect(subject).to be_a(::SuperGood::SolidusTaxjar::Reporting)
    end
  end

  describe ".logger" do
    subject { described_class.logger }

    let(:logger_double) { instance_double(Logger) }

    context "logger is set" do
      before do
        described_class.logger = logger_double
      end

      after do
        described_class.logger = nil
      end

      it "returns the logger" do
        expect(subject).to be(logger_double)
      end
    end

    context "no logger is set" do
      it "returns the Rails logger" do
        expect(subject).to be(Rails.logger)
      end
    end
  end

  describe "configuration" do
    describe ".cache_key" do
      subject { described_class.cache_key.call(order) }

      let(:order) { Spree::Order.new }

      it "returns the API params converted to JSON" do
        allow(SuperGood::SolidusTaxjar::ApiParams)
          .to receive(:order_params)
          .with(order)
          .and_return({some: "hash", with: "stuff", in: "it"})

        expect(subject).to eq '{"some":"hash","with":"stuff","in":"it"}'
      end
    end

    describe ".cache_duration" do
      subject { described_class.cache_duration }

      it "returns the default cache duration" do
        expect(subject).to eq(3.hours)
      end

      context "when set to another value" do
        before do
          described_class.cache_duration = 1.hour
        end

        it "returns the correct cache duration" do
          expect(subject).to eq(1.hour)
        end

        after do
          described_class.cache_duration = 3.hours
        end
      end
    end

    describe ".discount_calculator" do
      subject { described_class.discount_calculator }
      it { is_expected.to eq SuperGood::SolidusTaxjar::DiscountCalculator }
    end

    describe ".test_mode" do
      subject { described_class.test_mode }
      it { is_expected.to eq false }
    end

    describe ".exception_handler" do
      subject { described_class.exception_handler.call(exception) }

      let(:exception) { StandardError.new("Something happened") }

      it "reports the exception using the Rails logger" do
        expect(Rails.logger).to receive(:error).with(
          "An error occurred while fetching TaxJar tax rates - Something happened: Something happened"
        )
        subject
      end
    end

    describe ".taxable_address_check" do
      subject { described_class.taxable_address_check.call(address) }

      let(:address) { Spree::Address.new }

      it { is_expected.to eq true }
    end

    describe ".taxable_order_check" do
      subject { described_class.taxable_order_check.call(order) }

      let(:order) { Spree::Order.new }

      it { is_expected.to eq true }
    end

    describe ".shipping_tax_label_maker" do
      subject { described_class.shipping_tax_label_maker.call(shipment, shipping_tax) }
      let(:shipment) { Spree::Shipment.new }
      let(:shipping_tax) { BigDecimal("3.25") }
      it { is_expected.to eq "Sales Tax" }
    end

    describe ".line_item_tax_label_maker" do
      subject { described_class.line_item_tax_label_maker.call(taxjar_line_item, spree_line_item) }
      let(:taxjar_line_item) { instance_double Taxjar::BreakdownLineItem }
      let(:spree_line_item) { Spree::LineItem.new }
      it { is_expected.to eq "Sales Tax" }
    end

    describe ".shipping_calculator" do
      subject { described_class.shipping_calculator.call(order) }

      let(:order) { create :order }
      let(:shipment) { create :shipment, order: order, cost: 20 }

      before do
        create :adjustment, order: order, adjustable: shipment, amount: -10, eligible: true, source: create(:shipping_rate, shipment: shipment)
      end

      it "returns the shipment total including promotions" do
        expect(subject).to eq(10)
      end
    end

    describe ".job_queue" do
      subject { described_class.job_queue }

      it { is_expected.to eq :default }
    end

    describe ".configuration" do
      subject { described_class.configuration }

      it "returns a Configuration instance" do
        expect(subject).to be_instance_of(SuperGood::SolidusTaxjar::Configuration)
      end
    end
  end
end
