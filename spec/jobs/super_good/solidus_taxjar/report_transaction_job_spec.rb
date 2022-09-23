require "spec_helper"

RSpec.describe SuperGood::SolidusTaxjar::ReportTransactionJob do
  describe ".perform_now" do
    subject { described_class.perform_now(order) }

    let(:order) { create :order }
    let(:mock_reporting) { instance_double ::SuperGood::SolidusTaxjar::Reporting }
    let(:fake_order_transaction) { create :taxjar_order_transaction }

    before do
      allow(mock_reporting)
        .to receive(:show_or_create_transaction)
        .and_return(fake_order_transaction)
      allow(SuperGood::SolidusTaxjar).to receive(:reporting).and_return(mock_reporting)
    end

    it "reports the transaction when it performs the job" do
      subject

      expect(mock_reporting).to have_received(:show_or_create_transaction).with(order)
    end

    it "creates a transaction sync log with the order transaction" do
      expect { subject }
        .to change { ::SuperGood::SolidusTaxjar::TransactionSyncLog.count }
        .from(0)
        .to(1)

      expect(::SuperGood::SolidusTaxjar::TransactionSyncLog.last)
        .to have_attributes(
          status: "success",
          order_transaction: fake_order_transaction
        )
    end

    context "when a transaction sync batch is passed" do
      subject { described_class.perform_now(order, transaction_sync_batch) }

      let(:transaction_sync_batch) { create :transaction_sync_batch }

      it "creates a transaction sync log associated with the given batch" do
        expect { subject }
          .to change { ::SuperGood::SolidusTaxjar::TransactionSyncLog.count }
          .from(0)
          .to(1)

        expect(::SuperGood::SolidusTaxjar::TransactionSyncLog.last)
          .to have_attributes(
            transaction_sync_batch: transaction_sync_batch
          )
      end
    end

    context "when syncing to taxjar fails" do
      before do
        allow(mock_reporting)
        .to receive(:show_or_create_transaction)
        .and_raise(Taxjar::Error.new("something bad"))
      end

      it "creates a transaction sync log with the error message" do
        expect { subject }
          .to change { ::SuperGood::SolidusTaxjar::TransactionSyncLog.count }
          .from(0)
          .to(1)

        expect(::SuperGood::SolidusTaxjar::TransactionSyncLog.last)
          .to have_attributes(
            status: "error",
            error_message: "something bad"
          )
      end
    end
  end
end
