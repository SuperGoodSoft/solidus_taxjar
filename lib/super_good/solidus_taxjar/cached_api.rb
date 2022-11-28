module SuperGood
  module SolidusTaxjar
    class CachedApi
      # @param api [SuperGood::SolidusTaxjar::Api] instance of API wrapper
      def initialize(api: SuperGood::SolidusTaxjar.api)
        @api = api
      end

      # @param refresh [Boolean] forces a refresh of the cached regions
      def nexus_regions(refresh: false)
        Rails.cache.fetch(
          :nexus_regions,
          expires_in: SuperGood::SolidusTaxjar.cache_duration,
          force: refresh
        ) { api.nexus_regions }
      end

      private

      attr_reader :api
    end
  end
end
