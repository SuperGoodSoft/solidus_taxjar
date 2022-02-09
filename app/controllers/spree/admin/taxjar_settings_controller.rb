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
        if ENV["TAXJAR_API_KEY"]
          begin
            Rails.cache.write(
              :nexus_regions,
              SuperGood::SolidusTaxjar.api.nexus_regions,
              expires_in: 2.hours
            )
            flash[:success] = "Updated with new Nexus Regions"
          rescue Taxjar::Error => exception
            flash[:error] = exception.message
          end
        end
        redirect_back(fallback_location: spree.admin_taxjar_settings_path)
      end

      private

      def configuration_params
        params.require(:super_good_solidus_taxjar_configuration).permit(:preferred_reporting_enabled)
      end
    end
  end
end
