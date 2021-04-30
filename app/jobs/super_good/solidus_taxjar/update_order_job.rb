# frozen_string_literal: true

module SuperGood
  module SolidusTaxjar
    class UpdateOrderJob < ApplicationJob
      queue_as { SuperGood::SolidusTaxJar.job_queue }

      def perform(order)
        SuperGood::SolidusTaxJar::API.new.update_transaction_for(order)
      end
    end
  end
end
