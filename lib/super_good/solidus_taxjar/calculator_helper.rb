module SuperGood
  module SolidusTaxJar
    module CalculatorHelper
      extend ActiveSupport::Concern

      def incomplete_address?(address)
        return true if address.is_a?(Spree::Tax::TaxLocation)

        [
          address.address1,
          address.city,
          address.state&.abbr || address.state_name,
          address.zipcode,
          address.country&.iso
        ].any?(&:blank?)
      end

      def taxable_address?(address)
        SuperGood::SolidusTaxJar.taxable_address_check.call(address)
      end

      def cache
        if !Rails.env.test?
          Rails.cache.fetch(
            cache_key,
            expires_in: SuperGood::SolidusTaxJar.cache_duration
          ) { yield }
        else
          yield
        end
      end

      def exception_handler
        SuperGood::SolidusTaxJar.exception_handler
      end
    end
  end
end
