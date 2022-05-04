require "spec_helper"

RSpec.describe SuperGood::SolidusTaxjar::Reporting do
  let(:dummy_api) { instance_double ::SuperGood::SolidusTaxjar::Api }
  let(:order) { build :order, completed_at: 1.days.ago }
  let(:reporting) { described_class.new(api: dummy_api) }
  let(:test_order_transaction_id) { "R1234-transaction" }
  let(:test_refund_transaction_id) { "R1234-old-transaction-REFUND" }
  let(:test_transaction_date) { Date.new(2022, 1, 1) }
  let(:taxjar_order_response_double) {
    double(
      "Taxjar::Order",
      transaction_id: test_order_transaction_id,
      transaction_date: test_transaction_date
    )
  }
  let(:taxjar_refund_response_double) {
    double(
      "Taxjar::Refund",
      transaction_id: test_refund_transaction_id,
      transaction_date: test_transaction_date
    )
  }

  describe "#refund_and_create_transaction" do
    subject { reporting.refund_and_create_new_transaction(order) }

    let(:order) { create :order, completed_at: 1.days.ago, number: "R1234-old-transaction" }
    let!(:order_transaction_to_refund) {
      create(
        :taxjar_order_transaction,
        transaction_id: "R1234-old-transaction",
        transaction_date: Date.new(2021, 1, 1),
        order: order
      )
    }

    before do
      allow(dummy_api)
        .to receive(:create_refund_transaction_for)
        .and_return(taxjar_refund_response_double)

      allow(dummy_api)
        .to receive(:create_transaction_for)
        .and_return(taxjar_order_response_double)
    end

    it "refunds the transaction and creates a new one in TaxJar" do
      subject

      expect(dummy_api)
        .to have_received(:create_refund_transaction_for)
        .with(order)
      expect(dummy_api)
        .to have_received(:create_transaction_for)
        .with(order)
    end

    it "creates a refund transaction record" do
      expect { subject }
        .to change { SuperGood::SolidusTaxjar::RefundTransaction.count }
        .from(0)
        .to(1)

      expect(SuperGood::SolidusTaxjar::RefundTransaction.last).to have_attributes(
        transaction_id: test_refund_transaction_id,
        transaction_date: test_transaction_date,
        order_transaction: order_transaction_to_refund
      )
    end

    it "creates and returns a transaction for the order" do
      expect(subject).to be_a(SuperGood::SolidusTaxjar::OrderTransaction)
      expect(subject.persisted?).to be_truthy
      expect(subject).to have_attributes(
        transaction_id: test_order_transaction_id,
        transaction_date: test_transaction_date
      )
    end

    context "when Taxjar cannot create a refund transaction", :vcr do
      let(:reporting) { described_class.new }
      let(:order) { create(:completed_order_with_totals, number: "R1234-old-transaction") }
      let!(:tax_rate) { create(:tax_rate, name: "Sales Tax") }

      # We ensure that TaxJar cannot create a refund transaction refunding it
      # *before* the test scenario.
      before do
        taxjar_api_client = ::SuperGood::SolidusTaxjar::Api.default_taxjar_client
        begin
          taxjar_api_client.show_order("R1234-old-transaction")
        rescue Taxjar::Error::NotFound
          taxjar_client.create_order(
            ApiParams.transaction_params(order, "R1234-old-transaction")
          )
        end

        begin
          taxjar_api_client.show_refund("R1234-old-transaction-REFUND")
        rescue Taxjar::Error::NotFound
          taxjar_client.create_refund(
            ApiParams.refund_transaction_params(order, order_transaction_to_refund)
          )
        end
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

    context "the order has an existing transaction" do
      before do
        create :taxjar_order_transaction, transaction_id: test_order_transaction_id, transaction_date: test_transaction_date
      end

      it "returns the existing taxjar order transaction record" do
        allow(dummy_api)
          .to receive(:show_latest_transaction_for)
          .and_return(taxjar_order_response_double)

        subject

        expect(dummy_api)
          .to have_received(:show_latest_transaction_for)
          .with(order)

        expect(subject).to be_a(SuperGood::SolidusTaxjar::OrderTransaction)
        expect(subject.persisted?).to be_truthy
        expect(subject).to have_attributes(
          transaction_id: test_order_transaction_id,
          transaction_date: test_transaction_date
        )
      end
    end

    context "order doesn't have a transaction" do
      let(:order) { create :order, completed_at: 1.days.ago }

      context "TaxJar has no record of the transaction" do
        it "creates a transaction for the order" do
          allow(dummy_api)
            .to receive(:show_latest_transaction_for)
            .and_return(nil)

          allow(dummy_api)
            .to receive(:create_transaction_for)
            .and_return(taxjar_order_response_double)

          subject

          expect(dummy_api).to have_received(:show_latest_transaction_for).with(order)
          expect(dummy_api).to have_received(:create_transaction_for).with(order)

          expect(subject).to be_a(SuperGood::SolidusTaxjar::OrderTransaction)
          expect(subject.persisted?).to be_truthy
          expect(subject).to have_attributes(
            transaction_id: test_order_transaction_id,
            transaction_date: test_transaction_date
          )
        end
      end
    end
  end
end
