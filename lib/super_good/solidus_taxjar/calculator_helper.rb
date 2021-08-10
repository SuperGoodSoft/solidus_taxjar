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
        SuperGood::SolidusTaxjar.taxable_address_check.call(address)
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
    end
  end
end
