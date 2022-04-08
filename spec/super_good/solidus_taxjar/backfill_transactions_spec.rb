require "spec_helper"

RSpec.describe SuperGood::SolidusTaxjar::BackfillTransactions do
  describe ".call" do
    subject { described_class.new(api: api_spy).call }

    let!(:shipped_order) { create :shipped_order }
    let(:reporting_mock) { instance_double ::SuperGood::SolidusTaxjar::Reporting }
    let(:api_spy) { instance_spy(::SuperGood::SolidusTaxjar::Api) }
    let(:test_transaction_id) { "R1234-transaction" }

    around do |example|
      ::SuperGood::SolidusTaxjar.test_mode = true
      example.run
      ::SuperGood::SolidusTaxjar.test_mode = false
    end

    before do
      reported_order = create :shipped_order
      create(:taxjar_order_transaction, order: reported_order)
      create :order_ready_to_ship

      unreported_transaction = build(:taxjar_order_transaction, order: shipped_order, transaction_id: test_transaction_id)

      allow(SuperGood::SolidusTaxjar).to receive(:reporting).and_return(reporting_mock)
      allow(reporting_mock).to receive(:report_transaction).with(shipped_order) do
        unreported_transaction.save!
        unreported_transaction
      end
    end

    it "returns the numbers of the orders that have been pushed" do
      expect(subject).to eq([shipped_order.number])
    end

    it "creates a log of each synced order in the database" do
      expect { subject }.to change { SuperGood::SolidusTaxjar::TransactionSyncBatch.count }
        .from(0).to(1)
      transaction_sync_batch = SuperGood::SolidusTaxjar::TransactionSyncBatch.last
      expect(transaction_sync_batch.transaction_sync_logs.count).to eq(1)
      expect(transaction_sync_batch.transaction_sync_logs.last.order).to eq(shipped_order)
    end

    it "records the associated order, taxjar transaction, and status on each log" do
      subject
      sync_log = SuperGood::SolidusTaxjar::TransactionSyncLog.last

      expect(sync_log).to have_attributes(
        order: shipped_order,
        status: "success"
      )
      expect(sync_log.order_transaction).not_to be_nil
    end

    context "when the transaction cannot be created on TaxJar" do
      before do
        allow(reporting_mock)
          .to receive(:report_transaction)
          .and_raise(Taxjar::Error.new("api down"))
      end

      it "records a failure status in the log" do
        subject
        sync_log = SuperGood::SolidusTaxjar::TransactionSyncLog.last

        expect(sync_log).to have_attributes(
          order: shipped_order,
          status: "error",
          error_message: /api down/
        )

        expect(sync_log.order_transaction).to be_nil
      end
    end
  end
end
