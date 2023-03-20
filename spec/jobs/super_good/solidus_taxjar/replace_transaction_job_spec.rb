require "spec_helper"

RSpec.describe SuperGood::SolidusTaxjar::ReplaceTransactionJob do
  describe ".perform_later" do
    subject { described_class.perform_later(order) }

    let(:order) { create :order }
    let(:mock_reporting) { instance_double ::SuperGood::SolidusTaxjar::Reporting }
    let(:fake_order_transaction) { create :taxjar_order_transaction }
    let!(:fake_refund_transaction) { create :taxjar_refund_transaction, order_transaction: fake_order_transaction }

    before do
      allow(mock_reporting)
        .to receive(:refund_and_create_new_transaction)
        .and_return(fake_order_transaction)
      allow(SuperGood::SolidusTaxjar)
        .to receive(:reporting)
        .and_return(mock_reporting)
    end

    it "enqueues the job" do
      assert_enqueued_with(job: described_class, args: [order]) do
        subject
      end
    end

    it "replaces the transaction when it performs the job" do
      perform_enqueued_jobs do
        subject
      end

      expect(mock_reporting)
        .to have_received(:refund_and_create_new_transaction)
        .with(order)
    end

    it "creates multiple transaction sync logs with the order transactions and refund transactions" do
      expect { perform_enqueued_jobs { subject } }
        .to change { ::SuperGood::SolidusTaxjar::TransactionSyncLog.count }
        .by(1)

      expect(::SuperGood::SolidusTaxjar::TransactionSyncLog.last)
        .to have_attributes(
          status: "success",
          refund_transaction: fake_refund_transaction,
          order_transaction: fake_order_transaction
        )
    end

    context "when a replacing the transaction has already partially succeeded" do
      let(:fake_order_transaction) { create :taxjar_order_transaction }
      let(:fake_refund_transaction) { nil }

      before do
        allow(mock_reporting)
          .to receive(:refund_and_create_new_transaction)
          .and_return(fake_order_transaction)
      end

      it "creates a transaction sync log with the order transaction" do
        expect { perform_enqueued_jobs { subject } }
          .to change { ::SuperGood::SolidusTaxjar::TransactionSyncLog.count }
          .by(1)

        expect(::SuperGood::SolidusTaxjar::TransactionSyncLog.last)
          .to have_attributes(
            status: "success",
            order_transaction: fake_order_transaction,
            refund_transaction: nil
          )
      end
    end

    context "when replacing the transaction throws an error" do
      before do
        allow(mock_reporting)
          .to receive(:refund_and_create_new_transaction)
          .and_raise(Taxjar::Error.new("something bad"))
      end

      it "creates a transaction sync log with the error message" do
        expect { perform_enqueued_jobs {subject} }
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
