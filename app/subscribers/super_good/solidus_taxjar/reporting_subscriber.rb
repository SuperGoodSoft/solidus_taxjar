# frozen_string_literal: true

module SuperGood
  module SolidusTaxjar
    module ReportingSubscriber
      include Spree::Event::Subscriber

      event_action :create_order, event_name: 'order_finalized'
      event_action :update_order, event_name: 'order_recalculated'
      event_action :create_refund, event_name: 'reimbursement_reimbursed'

      def create_order(event)
        return unless SuperGood::SolidusTaxJar.reporting_enabled

        order = event.payload.fetch(:order)

        return unless SuperGood::SolidusTaxJar.taxable_order_check.call(order)

        SuperGood::SolidusTaxjar::CreateOrderJob.perform_later(order)
      end

      def update_order(event)
        return unless SuperGood::SolidusTaxJar.reporting_enabled

        order = event.payload.fetch(:order)

        return unless SuperGood::SolidusTaxJar.taxable_order_check.call(order)
        return unless order.complete?

        SuperGood::SolidusTaxjar::UpdateOrderJob.perform_later(order)
      end

      def create_refund(event)
        return unless SuperGood::SolidusTaxJar.reporting_enabled

        reimbursement = event.payload.fetch(:reimbursement)

        return unless SuperGood::SolidusTaxJar.taxable_order_check.call(reimbursement.order)

        SuperGood::SolidusTaxjar::CreateRefundJob.perform_later(reimbursement)
      end
    end
  end
end
