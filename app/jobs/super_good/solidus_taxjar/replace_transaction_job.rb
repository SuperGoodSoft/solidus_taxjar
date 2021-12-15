# frozen_string_literal: true

module SuperGood
  module SolidusTaxjar
    class ReplaceTransactionJob < ApplicationJob
      queue_as { SuperGood::SolidusTaxjar.job_queue }

      def perform(order)
        SuperGood::SolidusTaxjar.reporting.refund_and_create_new_transaction(order)
      end
    end
  end
end
