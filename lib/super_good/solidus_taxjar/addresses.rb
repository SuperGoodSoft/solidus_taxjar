module SuperGood
  module SolidusTaxJar
    class Addresses
      class << self
        def normalize(spree_address)
          new.normalize(spree_address)
        end
      end

      def initialize(api: ::SuperGood::SolidusTaxJar.api)
        @api = api
      end

      def normalize(spree_address)
        taxjar_address = api.validate_spree_address(spree_address).first

        return if taxjar_address.nil?

        Spree::Address.immutable_merge(spree_address, {
          country: us, # TaxJar only supports the US currently.
          state: state(taxjar_address.state),
          zipcode: taxjar_address.zip,
          city: taxjar_address.city,
          address1: taxjar_address.street
        })
      end

      private

      attr_reader :api

      def us
        Spree::Country.find_by iso: "US"
      end

      def state(abbr)
        us.states.find_by_abbr abbr
      end
    end
  end
end
