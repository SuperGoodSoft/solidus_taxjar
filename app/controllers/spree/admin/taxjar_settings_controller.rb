module Spree
  module Admin
    class TaxjarSettingsController < Spree::Admin::BaseController
      def edit
      end

      def update
        settings = SuperGood::SolidusTaxjar::Settings.find_or_create_by(id: 1)
        flash[:alert] = "TaxJar settings updated!"
        redirect_back(fallback_location: spree.admin_taxjar_settings_path)
      end
    end
  end
end
