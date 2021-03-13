# frozen_string_literal: true

module SuperGood
  module SolidusTaxjar
    module Spree::OrderUpdater
      module FireRecalculatedEvent
        def persist_totals
          Spree::Event.fire 'order_recalculated', order: order
          super
        end

        ::Spree::OrderUpdater.prepend(self) if Spree.solidus_gem_version < Gem::Version.new('2.11.0')
      end
    end
  end
end
