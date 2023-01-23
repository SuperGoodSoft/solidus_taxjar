require 'spree/preferences/persistable'

module SuperGood
  module SolidusTaxjar
    class Configuration < ::Spree::Base
      include ::Spree::Preferences::Persistable

      self.table_name = 'solidus_taxjar_configuration'
      preference :reporting_enabled_at_integer, :integer, default: nil

      def preferred_reporting_enabled
        preferred_reporting_enabled_at_integer.present?
      end

      def preferred_reporting_enabled_at
        Time.at(SuperGood::SolidusTaxjar.configuration.preferred_reporting_enabled_at_integer).to_datetime
      end

      class << self
        def default
          first || create
        end
      end
    end
  end
end
