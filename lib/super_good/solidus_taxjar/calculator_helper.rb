module SuperGood
  module SolidusTaxjar
    module CalculatorHelper
      extend ActiveSupport::Concern

      def incomplete_address?(address)
        return true if address.is_a?(::Spree::Tax::TaxLocation)

        fields = [
          address.address1,
          address.city,
          address.zipcode,
          address.country&.iso
        ]

        if state_required?(address.country)
          fields << (address.state&.abbr || address.state_name)
        end

        fields.any?(&:blank?)
      end

      def taxable_address?(address)
        SuperGood::SolidusTaxjar.taxable_address_check.call(address) &&
          address_in_nexus_region?(address)
      end

      def cache
        if !Rails.env.test?
          Rails.cache.fetch(
            cache_key,
            expires_in: SuperGood::SolidusTaxjar.cache_duration
          ) { yield }
        else
          yield
        end
      end

      def exception_handler
        SuperGood::SolidusTaxjar.exception_handler
      end

      # Only require a "state" value if this is an address for Canada or the
      # USA. This aligns with TaxJar's API requirement for `to_state`.
      #
      # @param country [Spree::Country] The country to check.
      # @return [Boolean] True if the "state" field is required for the country
      def state_required?(country)
        ["CA", "US"].include?(country&.iso)
      end

      private

      # Nexus regions are only a concept for US states. For non-US addresses
      # we always want to defer to the configuration in TaxJar.
      def address_in_nexus_region?(address)
        return true unless address&.country&.iso == "US"

        ::SuperGood::SolidusTaxjar::CachedApi
          .new
          .nexus_regions
          .map(&:region_code)
          .include?(address.state.abbr)
      end
    end
  end
end
