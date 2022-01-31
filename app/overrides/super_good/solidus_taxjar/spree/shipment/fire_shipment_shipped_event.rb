# frozen_string_literal: true

module SuperGood
  module SolidusTaxjar
    module Spree
      module Shipment
        module FireShipmentShippedEvent
          def after_ship
            ::Spree::Event.fire 'shipment_shipped', shipment: self
            super
          end

          ::Spree::Shipment.prepend(self)
        end
      end
    end
  end
end
