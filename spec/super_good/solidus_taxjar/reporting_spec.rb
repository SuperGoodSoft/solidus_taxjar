require "spec_helper"
RSpec.describe SuperGood::SolidusTaxjar::Reporting do
  describe "#report_transaction" do
    subject { described_class.new(api: dummy_api).report_transaction(order) }

    let(:dummy_api) {
      instance_double ::SuperGood::SolidusTaxjar::Api
    }

    let(:dummy_config) {
      class_double(::SuperGood::SolidusTaxjar).as_stubbed_const(:transfer_nested_constants => true)
    }

    let(:order) { build :order, completed_at: 1.days.ago }

    it "updates the transaction" do
      allow(dummy_config)
        .to receive(:reporting_enabled)
        .and_return(true)

      allow(dummy_api)
        .to receive(:show_latest_transaction_for)
        .with(order)
        .and_return("UPDATED-TRANSACTION-ID")

      expect(subject).to eq("UPDATED-TRANSACTION-ID")
    end

    context "order doesn't have a transaction" do
      it "creates the transaction for it" do
        allow(dummy_config)
          .to receive(:reporting_enabled)
          .and_return(true)

        allow(dummy_api)
          .to receive(:show_latest_transaction_for)
          .with(order)
          .and_raise(Taxjar::Error::NotFound)

        expect(dummy_api)
          .to receive(:create_transaction_for)
          .with(order)
          .and_return({})

        subject
      end
    end

    context "reporting is disabled" do
      it "returns nothing" do
        allow(dummy_config)
          .to receive(:reporting_enabled)
          .and_return(false)

        expect(subject).to be_nil
      end
    end
  end

  describe "#sync_transaction" do
    subject { described_class.new(api: dummy_api).sync_transaction(order) }

    let(:dummy_api) {
      instance_double ::SuperGood::SolidusTaxjar::Api
    }

    let(:dummy_config) {
      class_double(::SuperGood::SolidusTaxjar).as_stubbed_const(:transfer_nested_constants => true)
    }

    let(:order) { build :order, completed_at: 1.days.ago }

    it "refunds the existing transaction" do
      allow(dummy_config)
        .to receive(:reporting_enabled)
        .and_return(true)

      expect(dummy_api)
        .to receive(:create_refund_transaction_for)
        .with(order)
        .and_return({})

      expect(dummy_api)
        .to receive(:create_transaction_for)
        .with(order)
        .and_return({})

      subject
    end

    context "reporting is disabled" do
      it "returns nothing" do
        allow(dummy_config)
        .to receive(:reporting_enabled)
        .and_return(false)

        expect(subject).to be_nil
      end
    end
  end
end
