# frozen_string_literal: true

module SuperGood
  module SolidusTaxjar
    module Spree
      module OrderUpdater
        # Responsible for introducing the `order_recalculated` event for older
        # versions of Solidus (from 2.9 up until but not including 2.11) which
        # do not have this event. TaxJar transaction reporting relies on this
        # event firing when an order is recalculated.
        module FireRecalculatedEvent
          def persist_totals
            ::Spree::Event.fire 'order_recalculated', order: order
            super
          end

          ::Spree::OrderUpdater.prepend(self) if ::Spree.solidus_gem_version < Gem::Version.new('2.11.0')
        end
      end
    end
  end
end
