module Spree
  module Admin
    class TaxjarSettingsController < Spree::Admin::BaseController
      def edit
        @configuration = SuperGood::SolidusTaxjar.configuration
        @nexus_regions = Rails.cache.fetch(:nexus_regions) || []
      end

      def update
        if SuperGood::SolidusTaxjar.configuration.update(configuration_params)
          flash[:success] = "TaxJar settings updated!"
        else
          flash[:alert] = "Failed to update settings!"
        end
        redirect_back(fallback_location: spree.admin_taxjar_settings_path)
      end

      def sync_nexus_regions
        api_sync do
          Rails.cache.write(
            :nexus_regions,
            SuperGood::SolidusTaxjar.api.nexus_regions,
            expires_in: SuperGood::SolidusTaxjar.cache_duration
          )
          flash[:success] = "Updated with new Nexus Regions"
        end
      end

      def sync_tax_categories
        api_sync do
          Rails.cache.write(
            :tax_categories,
            SuperGood::SolidusTaxjar.api.tax_categories,
            expires_in: 30.days
          )
          flash[:success] = "Updated with new tax categories"
        end
      end

      private

      def configuration_params
        params.require(:super_good_solidus_taxjar_configuration).permit(:preferred_reporting_enabled)
      end

      def api_sync
        begin
          yield
        rescue Taxjar::Error => exception
          flash[:error] = "Failed to complete request to TaxJar: #{exception.message}"
        end
        redirect_back(fallback_location: spree.admin_taxjar_settings_path)
      end
    end
  end
end
