# frozen_string_literal: true

module SuperGoodSolidusTaxjar
  class Engine < Rails::Engine
    isolate_namespace Spree
    engine_name 'super_good_solidus_taxjar'

    if Spree.solidus_gem_version < Gem::Version.new('2.11.0')
      require root.join('app/subscribers/super_good/solidus_taxjar/spree/reporting_subscriber')
      SuperGood::SolidusTaxjar::Spree::ReportingSubscriber.subscribe!
    end

    include SolidusSupport::EngineExtensions
  end
end
