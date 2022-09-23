# frozen_string_literal: true

module SuperGood
  module SolidusTaxjar
    class ReportTransactionJob < ApplicationJob
      queue_as { SuperGood::SolidusTaxjar.job_queue }

      def perform(order)
        transaction_sync_log = SuperGood::SolidusTaxjar::TransactionSyncLog.create!(
          order: order
        )
        begin
          order_transaction = SuperGood::SolidusTaxjar.reporting.show_or_create_transaction(order)
          transaction_sync_log.update!(order_transaction: order_transaction, status: :success)
        rescue Taxjar::Error => exception
          transaction_sync_log.update!(status: :error, error_message: exception.message)
        end
      end
    end
  end
end
