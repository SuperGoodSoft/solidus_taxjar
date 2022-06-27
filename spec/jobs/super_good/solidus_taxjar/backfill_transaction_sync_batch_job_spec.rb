require "spec_helper"

RSpec.describe SuperGood::SolidusTaxjar::BackfillTransactionSyncBatchJob do
  describe "#perform" do
    subject { described_class.new.perform(batch) }

    let!(:shipped_order) { create :shipped_order }
    let(:reporting_mock) { instance_double ::SuperGood::SolidusTaxjar::Reporting }
    let(:test_transaction_id) { "R1234-transaction" }
    let(:batch) { create :transaction_sync_batch }

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
      allow(reporting_mock).to receive(:show_or_create_transaction) do
        unreported_transaction.save!
        unreported_transaction
      end
    end

    it "reports the transaction to TaxJar" do
      subject

      expect(reporting_mock).to have_received(:show_or_create_transaction).with(shipped_order)
    end

    it "creates a log of each synced order in the database" do
      subject
      expect(batch.transaction_sync_logs.count).to eq(1)
      expect(batch.transaction_sync_logs.last.order).to eq(shipped_order)
    end

    it "records the associated order, taxjar transaction, and status on each log" do
      subject
      sync_log = batch.transaction_sync_logs.last

      expect(sync_log).to have_attributes(
        order: shipped_order,
        status: "success"
      )
      expect(sync_log.order_transaction).not_to be_nil
    end

    context "when the transaction cannot be created on TaxJar" do
      before do
        allow(reporting_mock)
          .to receive(:show_or_create_transaction)
          .and_raise(Taxjar::Error.new("api down"))
      end

      it "records a failure status in the log" do
        subject
        sync_log = batch.transaction_sync_logs.last

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
