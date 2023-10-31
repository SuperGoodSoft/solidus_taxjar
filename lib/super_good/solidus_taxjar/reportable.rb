module SuperGood
  module SolidusTaxjar
    module Reportable
      ORDER_TOO_OLD_MESSAGE = "Order cannot be synced because it was completed before TaxJar reporting was enabled"

      def self.included(base)
        # Omnes subscribers are classes, whereas the legacy event system uses
        # modules for subscribers. The type check ensures this is forwards
        # compatible and can be removed when we drop support for the legacy
        # event system.
        base.extend(base) unless base.is_a?(Class)
      end

      def with_reportable(order, &block)
        raise "Please provide a block!" unless block_given?

        return unless order_reportable?(order)
        return if completed_before_reporting_enabled?(order)
        return unless order.taxjar_order_transactions.none?

        yield
      end

      def with_replaceable(order, &block)
        return unless order_reportable?(order)
        return if completed_before_reporting_enabled?(order)
        return unless transaction_replaceable?(order)

        yield
      end

      # @return [Boolean] true if the TaxJar reporting is currently enabled
      #   and the order meets all the other requirements for reporting.
      def order_reportable?(order)
        return SuperGood::SolidusTaxjar.configuration.preferred_reporting_enabled &&
          order.completed? &&
          order.shipped? &&
          order.payment_state == "paid"
      end

      # @return [Boolean] true if the transaction has been previously reported
      #   to TaxJar, the order is currently in `paid` state and there is a
      #   difference between the total (before tax) on the order in Solidus
      #   and the transaction amount on TaxJar.
      def transaction_replaceable?(order)
        order.taxjar_order_transactions.present? &&
          amount_changed?(order)
      end

      private

      def completed_before_reporting_enabled?(order)
        configuration = SuperGood::SolidusTaxjar.configuration

        completed_before_reporting_enabled = configuration.preferred_reporting_enabled &&
          configuration.preferred_reporting_enabled_at > order.completed_at

        if completed_before_reporting_enabled
          log_order_too_old_to_sync(order)
        end

        completed_before_reporting_enabled
      end

      # Logs and notifies the custom exception handler for orders which are
      # too old to be reported. If a log for this already exists a new one
      # won't be created and the exception handler won't be called.
      def log_order_too_old_to_sync(order)
        sync_log = order.taxjar_transaction_sync_logs.find_or_initialize_by(
          status: :error,
          error_message: ORDER_TOO_OLD_MESSAGE
        )

        unless sync_log.persisted?
          sync_log.save!

          SuperGood::SolidusTaxjar.exception_handler.call(
            RuntimeError.new(ORDER_TOO_OLD_MESSAGE)
          )
        end
      end

      def amount_changed?(order)
        # We use `order.payment_total` to ensure we capture any total changes
        # from refunds.
        SuperGood::SolidusTaxjar.api.show_latest_transaction_for(order).amount !=
          (order.payment_total - order.additional_tax_total)
      end
    end
  end
end
