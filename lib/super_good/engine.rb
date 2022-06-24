# frozen_string_literal: true

module SuperGoodSolidusTaxjar
  class Engine < Rails::Engine
    isolate_namespace Spree
    engine_name 'super_good_solidus_taxjar'

    # Solidus versions prior to 2.11.0 do not support auto-loading of subscribers
    # so we need to manually register the reporting subscriber with the event
    # bus.
    if Spree.solidus_gem_version < Gem::Version.new('2.11.0')
      require root.join('app/subscribers/super_good/solidus_taxjar/spree/reporting_subscriber')
      SuperGood::SolidusTaxjar::Spree::ReportingSubscriber.subscribe!
    end

    include SolidusSupport::EngineExtensions
  end
end
