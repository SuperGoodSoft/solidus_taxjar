module SuperGood
  module SolidusTaxjar
    module Generators
      class InstallGenerator < Rails::Generators::Base
        class_option :auto_run_migrations, type: :boolean, default: false

        def create_initializer_file
          solidus_initializer_path = "config/initializers/solidus.rb"

          create_file(solidus_initializer_path) unless File.exists?(solidus_initializer_path)
          append_to_file(solidus_initializer_path, <<~INIT)
            Spree.config do |config|
              config.tax_calculator_class = SuperGood::SolidusTaxjar::TaxCalculator
            end
          INIT
        end

        def add_migrations
          run 'bin/rails railties:install:migrations FROM=solidus_taxjar'
        end

        def run_migrations
          run_migrations = options[:auto_run_migrations] || ['', 'y', 'Y'].include?(ask('Would you like to run the migrations now? [Y/n]'))
          if run_migrations
            run 'bin/rails db:migrate'
          else
            puts 'Skipping bin/rails db:migrate, don\'t forget to run it!'
          end
        end
      end
    end
  end
end
