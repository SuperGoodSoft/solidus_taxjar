module Spree
  module Admin
    class TransactionSyncBatchesController < Spree::Admin::BaseController
      def index
        @batches = SuperGood::SolidusTaxjar::TransactionSyncBatch.all.page(params[:page]).per(params[:per_page])
      end

      def show
        @batch = SuperGood::SolidusTaxjar::TransactionSyncBatch.find(params[:id])
      end

      def create
        batch = ::SuperGood::SolidusTaxjar::BackfillTransactions.new.call(start_date: params[:start_date], end_date: params[:end_date])
        redirect_to spree.admin_transaction_sync_batch_path(batch)
      end
    end
  end
end
