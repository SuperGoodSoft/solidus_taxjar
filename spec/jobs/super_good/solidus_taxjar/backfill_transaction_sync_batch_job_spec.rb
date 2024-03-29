require "spec_helper"

RSpec.describe SuperGood::SolidusTaxjar::BackfillTransactionSyncBatchJob do
  describe "#perform" do
    subject do
      perform_enqueued_jobs do
        described_class.new.perform(batch)
      end
    end

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

    context "batch has start date" do
      let(:batch) { create :transaction_sync_batch, start_date: 2.days.ago.to_date }
      let(:start_date) { 2.days.ago.to_date }

      before do
        old_order = create :shipped_order
        old_order.update_column(:completed_at, 3.days.ago)

        shipped_order.update_column(:completed_at, Date.today.end_of_day)
      end

      it "syncs orders in the date range" do
        subject
        expect(batch.orders).to contain_exactly(shipped_order)
      end

    end

    context "batch has start and end date" do
      let(:batch) { create :transaction_sync_batch, start_date: 3.days.ago.to_date, end_date: 2.days.ago.to_date } 

      before do
        old_order = create :shipped_order
        old_order.update_column(:completed_at, 4.days.ago)

        new_order = create :shipped_order
        new_order.update_column(:completed_at, Date.today.end_of_day)

        shipped_order.update_column(:completed_at, 2.days.ago)
      end

      it "syncs orders in the date range" do
        subject
        expect(batch.orders).to contain_exactly(shipped_order)
      end
    end
  end
end
