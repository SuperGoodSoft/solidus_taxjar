require "spec_helper"

RSpec.describe SuperGood::SolidusTaxjar::BackfillTransactions do
  describe "#call" do
    subject { described_class.new.call }

    it "returns a new transaction sync batch" do
      expect(subject).to be_a(SuperGood::SolidusTaxjar::TransactionSyncBatch)
    end

    it "queues a job to backfill the transactions in the batch" do
      expect { subject }
        .to have_enqueued_job(SuperGood::SolidusTaxjar::BackfillTransactionSyncBatchJob)
        .with(kind_of(SuperGood::SolidusTaxjar::TransactionSyncBatch))
    end
  end
end
