module Spree
  module Admin
    class TransactionSyncBatchesController < Spree::Admin::BaseController
      def index
        @batches = SuperGood::SolidusTaxjar::TransactionSyncBatch.all.page(params[:page]).per(params[:per_page])
      end
    end
  end
end
