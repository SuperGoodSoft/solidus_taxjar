module SuperGood
  module SolidusTaxjar
    module Spree
      module ReportingSubscriber
        include ::Spree::Event::Subscriber

        if ::Spree::Event.method_defined?(:register)
          ::Spree::Event.register("shipment_shipped")
        end
        event_action :report_transaction, event_name: :shipment_shipped

        def report_transaction(event)
          return unless SuperGood::SolidusTaxjar.configuration.preferred_reporting_enabled
          SuperGood::SolidusTaxjar::ReportTransactionJob.perform_later(event.payload[:shipment].order)
        end
      end
    end
  end
end
