module SuperGood
  module SolidusTaxjar
    module Generators
      class InstallGenerator < Rails::Generators::Base
        def create_initializer_file
          solidus_initializer_path = "config/initializers/solidus.rb"

          create_file(solidus_initializer_path) unless File.exists?(solidus_initializer_path)
          append_to_file(solidus_initializer_path, <<~INIT)
            Spree.config do |config|
              config.tax_calculator_class = SuperGood::SolidusTaxjar::TaxCalculator
            end
          INIT
        end
      end
    end
  end
end
