# frozen_string_literal: true

module SuperGood
  module SolidusTaxjar
    class CreateRefundJob < ApplicationJob
      queue_as { SuperGood::SolidusTaxJar.job_queue }

      def perform(reimbursement)
        SuperGood::SolidusTaxJar::API.new.create_refund_for(reimbursement)
      end
    end
  end
end
