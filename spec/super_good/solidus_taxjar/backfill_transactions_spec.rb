require "spec_helper"

RSpec.describe SuperGood::SolidusTaxjar::BackfillTransactions do
  describe "#call" do
    subject { described_class.new.call(start_date: start_date.to_s, end_date: end_date.to_s) }

    let(:start_date) { 1.day.ago.to_date }
    let(:end_date) { Date.today }

    it "returns a new transaction sync batch" do
      expect(subject).to be_a(SuperGood::SolidusTaxjar::TransactionSyncBatch)
    end

    it "has the start and end date" do
      expect(subject).to have_attributes({start_date: start_date, end_date: end_date})
    end

    it "queues a job to backfill the transactions in the batch" do
      expect { subject }
        .to have_enqueued_job(SuperGood::SolidusTaxjar::BackfillTransactionSyncBatchJob)
        .with(kind_of(SuperGood::SolidusTaxjar::TransactionSyncBatch))
    end
  end
end
