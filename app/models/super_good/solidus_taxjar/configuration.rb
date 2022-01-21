require 'spree/preferences/persistable'

module SuperGood
  module SolidusTaxjar
    class Configuration < ::Spree::Base
      include ::Spree::Preferences::Persistable

      self.table_name = 'solidus_taxjar_configuration'
      preference :reporting_enabled, :boolean, default: false

      class << self
        def default
          first || create
        end
      end
    end
  end
end
