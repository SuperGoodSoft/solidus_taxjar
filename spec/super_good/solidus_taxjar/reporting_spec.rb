require "spec_helper"

RSpec.describe SuperGood::SolidusTaxjar::Reporting do
  describe "#report_transaction" do
    subject { described_class.new(api: dummy_api).report_transaction(order) }

    let(:dummy_api) { instance_double ::SuperGood::SolidusTaxjar::Api }

    context "the order has an existing transaction" do
      let(:order) { build :order, completed_at: 1.days.ago }
      let(:test_transaction_id) { "R1234-transaction" }
      let(:test_transaction_date) { Date.new(2022, 1, 1) }
      let(:taxjar_order_response_double) {
        double(
          "Taxjar::Order",
          transaction_id: test_transaction_id,
          transaction_date: test_transaction_date
        )
      }

      before do
        create :taxjar_order_transaction, transaction_id: test_transaction_id, transaction_date: test_transaction_date
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
          transaction_id: test_transaction_id,
          transaction_date: test_transaction_date
        )
      end
    end

    context "the order doesn't have a transaction" do
      let(:order) { create :order, completed_at: 1.days.ago }

      context "the Solidus application has no record of the transaction" do
        it "does nothing (until this feature is implemented)" do
          allow(dummy_api)
            .to receive(:show_latest_transaction_for)
            .with(order)
            .and_raise(NotImplementedError)
          allow(dummy_api).to receive(:create_transaction_for)

          expect(subject).to be_nil

          expect(dummy_api).to have_received(:show_latest_transaction_for).with(order)
          expect(dummy_api).not_to have_received(:create_transaction_for)
        end
      end

      context "TaxJar has no record of the transaction" do
        let(:test_transaction_id) { "R1234-transaction" }
        let(:test_transaction_date) { Date.new(2022, 1, 1) }
        let(:taxjar_order_response_double) {
          double(
            "Taxjar::Order",
            transaction_id: test_transaction_id,
            transaction_date: test_transaction_date
          )
        }

        it "creates a transaction for the order" do
          allow(dummy_api)
            .to receive(:show_latest_transaction_for)
            .and_raise(Taxjar::Error::NotFound)

          allow(dummy_api)
            .to receive(:create_transaction_for) do
              # Currently, the API method is responsible for creating the transaction object, so
              # we also have to mock out that behavior. This will be removed in an upcoming refactor.
              create :taxjar_order_transaction, transaction_id: test_transaction_id, transaction_date: test_transaction_date
              taxjar_order_response_double
            end

          subject

          expect(dummy_api).to have_received(:show_latest_transaction_for).with(order)
          expect(dummy_api).to have_received(:create_transaction_for).with(order)

          expect(subject).to be_a(SuperGood::SolidusTaxjar::OrderTransaction)
          expect(subject.persisted?).to be_truthy
          expect(subject).to have_attributes(
            transaction_id: test_transaction_id,
            transaction_date: test_transaction_date
          )
        end
      end
    end
  end
end
