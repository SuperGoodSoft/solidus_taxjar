require "spec_helper"

RSpec.describe SuperGood::SolidusTaxjar::TransactionSyncBatch do
  describe "#status" do
    subject { transaction_sync_batch.status }

    let(:transaction_sync_batch) { create(:transaction_sync_batch, transaction_sync_logs: transaction_sync_logs) }

    context "all logs have status 'success'" do
      let(:transaction_sync_logs) { build_list(:transaction_sync_log, 2, status: :success) }

      it "returns 'success'" do
        expect(subject).to eq "success"
      end
    end

    context "one or more logs have status 'error'" do
      let(:transaction_sync_logs) { [
        build(:transaction_sync_log, status: :success),
        build(:transaction_sync_log, status: :error)
      ] }

      it "returns 'error'" do
        expect(subject).to eq "error"
      end
    end

    context "one or more logs have status 'processing'" do
      let(:transaction_sync_logs) { [
        build(:transaction_sync_log, status: :success),
        build(:transaction_sync_log, status: :processing),
        build(:transaction_sync_log, status: :error)
      ] }

      it "returns 'processing'" do
        expect(subject).to eq "processing"
      end
    end

    context "with an empty batch" do
      let(:transaction_sync_logs) { [] }

      it "returns 'success'" do
        expect(subject).to eq "success"
      end
    end
  end
end
