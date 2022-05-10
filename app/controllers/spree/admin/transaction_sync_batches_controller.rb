module Spree
  module Admin
    class TransactionSyncBatchesController < Spree::Admin::BaseController
      def index
        @batches = SuperGood::SolidusTaxjar::TransactionSyncBatch.all
      end
    end
  end
end
