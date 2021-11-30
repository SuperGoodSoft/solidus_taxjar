module Spree
  module Admin
    class TaxjarSettingsController < Spree::Admin::BaseController
      def edit
        @settings = SuperGood::SolidusTaxjar::Settings.find_or_create_by(id: 1)
      end

      def update
        settings = SuperGood::SolidusTaxjar::Settings.find_or_create_by(id: 1)
        settings.update!(settings_params)
        flash[:alert] = "TaxJar settings updated!"
        redirect_back(fallback_location: spree.admin_taxjar_settings_path)
      end

      private

      def settings_params
        params.require(:super_good_solidus_taxjar_settings).permit(:reporting_enabled)
      end
    end
  end
end
