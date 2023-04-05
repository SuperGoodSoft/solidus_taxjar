module SuperGood
  module SolidusTaxjar
    module Reportable
      ORDER_TOO_OLD_MESSAGE = "Order cannot be synced because it was completed before TaxJar reporting was enabled"

      def self.included(base)
        base.extend base
      end

      def with_reportable(order, &block)
        raise "Please provide a block!" unless block_given?

        return unless order_reportable?(order)

        if completed_before_reporting_enabled?(order)
          order.taxjar_transaction_sync_logs.create!(
            status: :error,
            error_message: ORDER_TOO_OLD_MESSAGE
          )
          SuperGood::SolidusTaxjar.exception_handler.call(
            RuntimeError.new(ORDER_TOO_OLD_MESSAGE)
          )
          return
        end

        yield
      end

      private

      def order_reportable?(order)
        SuperGood::SolidusTaxjar.configuration.preferred_reporting_enabled
      end

      def completed_before_reporting_enabled?(order)
        configuration = SuperGood::SolidusTaxjar.configuration

        configuration.preferred_reporting_enabled &&
          configuration.preferred_reporting_enabled_at > order.completed_at
      end
    end
  end
end
