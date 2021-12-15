require "spec_helper"

RSpec.describe SuperGood::SolidusTaxjar::Reporting do
  let(:dummy_api) { instance_double ::SuperGood::SolidusTaxjar::Api }
  let(:order) { build :order, completed_at: 1.days.ago }
  let(:reporting) { described_class.new(api: dummy_api) }

  describe "#refund_and_create_transaction" do
    subject { reporting.refund_and_create_new_transaction(order) }

    it "refunds the transaction and creates a new one in TaxJar" do
      expect(dummy_api)
        .to receive(:create_refund_transaction_for)
        .with(order)
      expect(dummy_api)
        .to receive(:create_transaction_for)
        .with(order)

      subject
    end

    context "when Taxjar cannot create a refund transaction", :vcr do
      let(:reporting) { described_class.new }
      let(:order) { create(:completed_order_with_totals) }
      let!(:tax_rate) { create(:tax_rate, name: "Sales Tax") }

      # We ensure that TaxJar cannot create a refund transaction refunding it
      # *before* the test scenario.
      before do
        SuperGood::SolidusTaxjar.api.create_transaction_for(order)
        SuperGood::SolidusTaxjar.api.create_refund_transaction_for(order)
      end

      it "raises an error" do
        expect { subject }.to raise_error(
          Taxjar::Error::UnprocessableEntity,
          "Provider tranx already imported for your user account"
        )
      end

      it "doesn't create a new transaction" do
        expect(SuperGood::SolidusTaxjar.api)
          .not_to receive(:create_transaction_for)

        begin
          subject
        rescue Taxjar::Error::UnprocessableEntity
          nil
        end
      end
    end
  end

  describe "#show_or_create_transaction" do
    subject { reporting.show_or_create_transaction(order) }

    it "shows the latest transaction for the order" do
      allow(dummy_api)
        .to receive(:show_latest_transaction_for)
        .with(order)
        .and_return("UPDATED-TRANSACTION-ID")

      expect(subject).to eq("UPDATED-TRANSACTION-ID")
    end

    context "order doesn't have a transaction" do
      context "the Solidus application has no record of the transaction" do
        it "does nothing (until this feature is implemented)" do
          allow(dummy_api)
            .to receive(:show_latest_transaction_for)
            .with(order)
            .and_raise(NotImplementedError)

          expect(dummy_api).not_to receive(:create_transaction_for)

          subject
        end
      end

      context "TaxJar has no record of the transaction" do
        it "creates the transaction for it" do
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
    end
  end
end
