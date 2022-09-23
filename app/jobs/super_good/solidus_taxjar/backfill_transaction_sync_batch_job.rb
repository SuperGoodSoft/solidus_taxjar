# frozen_string_literal: true

module SuperGood
  module SolidusTaxjar
    class BackfillTransactionSyncBatchJob < ApplicationJob
      queue_as { SuperGood::SolidusTaxjar.job_queue }

      def perform(transaction_sync_batch)
        ::Spree::Order.complete.where(shipment_state: 'shipped').find_each do |order|
          next if order.taxjar_order_transactions.any?
          SuperGood::SolidusTaxjar::ReportTransactionJob.perform_later(order, transaction_sync_batch)
        end
      end
    end
  end
end
