module SuperGood
  module SolidusTaxjar
    module Spree
      module ReportingSubscriber
        include ::Spree::Event::Subscriber
        event_action :report_transaction, event_name: :shipment_shipped

        def report_transaction(event)
          SuperGood::SolidusTaxjar.reporting.report_transaction(event.payload[:shipment].order)
        end
      end
    end
  end
end
