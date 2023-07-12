# frozen_string_literal: true

module SuperGoodSolidusTaxjar
  class Engine < Rails::Engine
    isolate_namespace Spree
    engine_name 'super_good_solidus_taxjar'

    include SolidusSupport::EngineExtensions
  end
end
