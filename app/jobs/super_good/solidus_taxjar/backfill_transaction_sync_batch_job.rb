# frozen_string_literal: true

module SuperGood
  module SolidusTaxjar
    class BackfillTransactionSyncBatchJob < ApplicationJob
      queue_as { SuperGood::SolidusTaxjar.job_queue }

      def perform(transaction_sync_batch)
        complete_orders = ::Spree::Order.complete.where(shipment_state: 'shipped')
        if transaction_sync_batch.start_date
          complete_orders = complete_orders.where("completed_at >= ?", transaction_sync_batch.start_date.beginning_of_day)
        end
        if transaction_sync_batch.end_date
          complete_orders = complete_orders.where("completed_at <= ?", transaction_sync_batch.end_date.end_of_day)
        end
        complete_orders.find_each do |order|
          next if order.taxjar_order_transactions.any?
          SuperGood::SolidusTaxjar::ReportTransactionJob.perform_later(order, transaction_sync_batch)
        end
      end
    end
  end
end
