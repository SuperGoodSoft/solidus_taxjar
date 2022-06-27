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

    it "creates a batch with a log for the order" do
      perform_enqueued_jobs do
        expect { subject }
          .to change { SuperGood::SolidusTaxjar::TransactionSyncBatch.count }
          .from(0)
          .to(1)
      end

      batch = SuperGood::SolidusTaxjar::TransactionSyncBatch.last
      expect(batch.transaction_sync_logs.last.order).to eq order
    end
  end
end
