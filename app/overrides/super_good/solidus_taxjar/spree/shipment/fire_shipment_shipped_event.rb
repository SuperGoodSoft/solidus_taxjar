# frozen_string_literal: true

module SuperGood
  module SolidusTaxjar
    module Spree
      module Shipment
        module FireShipmentShippedEvent
          def after_ship
            super

            SolidusSupport::LegacyEventCompat::Bus.publish(
              :shipment_shipped,
              shipment: self
            )
          end

          ::Spree::Shipment.prepend(self)
        end
      end
    end
  end
end
