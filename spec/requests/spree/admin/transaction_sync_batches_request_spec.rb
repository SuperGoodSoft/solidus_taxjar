require 'spec_helper'

RSpec.describe Spree::Admin::TransactionSyncBatchesController, :vcr, :type => :request do
  extend Spree::TestingSupport::AuthorizationHelpers::Request
  stub_authorization!

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "#create" do
    subject { post spree.admin_transaction_sync_batches_path }

    let!(:order) { create(:shipped_order) }

    it "creates a batch" do
      perform_enqueued_jobs do
        expect { subject }
          .to change { SuperGood::SolidusTaxjar::TransactionSyncBatch.count }
          .from(0)
          .to(1)
        batch = SuperGood::SolidusTaxjar::TransactionSyncBatch.last
        expect(batch).to have_attributes({start_date: nil, end_date: nil})
      end
    end

    it "creates a log in the batch with an order" do
      perform_enqueued_jobs do
        subject

        batch = SuperGood::SolidusTaxjar::TransactionSyncBatch.last
        expect(batch.transaction_sync_logs.last.order).to eq order
      end
    end

    context "user supplies a start date" do
      subject { post spree.admin_transaction_sync_batches_path, params: {start_date: 1.day.ago.to_date.to_s} }

      it "creates a batch" do
        perform_enqueued_jobs do
          expect { subject }
            .to change { SuperGood::SolidusTaxjar::TransactionSyncBatch.count }
            .from(0)
            .to(1)
          batch = SuperGood::SolidusTaxjar::TransactionSyncBatch.last
          expect(batch).to have_attributes({start_date: 1.day.ago.to_date, end_date: nil})
        end
      end

      context "user supplies start and end date" do
        subject { post spree.admin_transaction_sync_batches_path, params: {start_date: 1.day.ago.to_date.to_s, end_date: Date.today.to_s} }

        it "creates a batch" do
          perform_enqueued_jobs do
            expect { subject }
              .to change { SuperGood::SolidusTaxjar::TransactionSyncBatch.count }
              .from(0)
              .to(1)
            batch = SuperGood::SolidusTaxjar::TransactionSyncBatch.last
            expect(batch).to have_attributes({start_date: 1.day.ago.to_date, end_date: Date.today})
          end
        end
      end
    end
  end

  describe "#show" do
    subject { get spree.admin_transaction_sync_batch_path(transaction_sync_batch) }

    let(:error_message) { "Uh Oh" }
    let(:transaction_sync_batch) { create :transaction_sync_batch, transaction_sync_logs: [transaction_sync_log] }
    let(:transaction_sync_log) { build :transaction_sync_log, error_message: error_message }

    it "renders the transaction sync log error message" do
      subject
      expect(response.body).to include(error_message)
    end
  end
end
