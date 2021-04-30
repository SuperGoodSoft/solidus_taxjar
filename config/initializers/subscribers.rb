# frozen_string_literal: true

if Spree.solidus_gem_version < Gem::Version.new('2.11.0')
  require SuperGoodSolidusTaxjar::Engine.root.join('app/subscribers/super_good/solidus_taxjar/reporting_subscriber')

  SuperGood::SolidusTaxjar::ReportingSubscriber.subscribe!
end
