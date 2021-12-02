module Spree
  module Admin
    class TaxjarSettingsController < Spree::Admin::BaseController
      def edit
        @configuration = SuperGood::SolidusTaxjar.configuration
      end

      def update
        if SuperGood::SolidusTaxjar.configuration.update(configuration_params)
          flash[:success] = "TaxJar settings updated!"
        else
          flash[:alert] = "Failed to update settings!"
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
