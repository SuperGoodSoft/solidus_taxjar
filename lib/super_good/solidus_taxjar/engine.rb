module SuperGood
  module SolidusTaxjar
    class Engine < ::Rails::Engine
      engine_name 'super_good_solidus_taxjar'

      include SolidusSupport::EngineExtensions
    end
  end
end