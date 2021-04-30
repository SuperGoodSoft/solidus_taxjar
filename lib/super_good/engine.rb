# frozen_string_literal: true

module SuperGoodSolidusTaxjar
  class Engine < Rails::Engine
    include SolidusSupport::EngineExtensions

    isolate_namespace Spree
    engine_name 'super_good_solidus_taxjar'
  end
end
