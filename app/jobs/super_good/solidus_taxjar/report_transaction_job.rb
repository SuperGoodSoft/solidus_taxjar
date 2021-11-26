# frozen_string_literal: true

module SuperGood
  module SolidusTaxjar
    class ReportTransactionJob < ApplicationJob
      queue_as { SuperGood::SolidusTaxjar.job_queue }

      def perform(order)
        SuperGood::SolidusTaxjar.reporting.report_transaction(order)
      end
    end
  end
end
