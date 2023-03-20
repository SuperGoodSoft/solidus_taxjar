# frozen_string_literal: true

module SuperGood
  module SolidusTaxjar
    class ReplaceTransactionJob < ApplicationJob
      queue_as { SuperGood::SolidusTaxjar.job_queue }

      def perform(order)
        order_transaction = SuperGood::SolidusTaxjar.reporting.refund_and_create_new_transaction(order)

        SuperGood::SolidusTaxjar::TransactionSyncLog.create!(
          order: order,
          refund_transaction: order_transaction.refund_transaction,
          order_transaction: order_transaction,
          status: :success
        )

      rescue Taxjar::Error => exception
        SuperGood::SolidusTaxjar::TransactionSyncLog.create!(
          order: order,
          status: :error,
          error_message: exception.message
        )
      end
    end
  end
end
