module Spree
  module Admin
    class TaxjarSettingsController < Spree::Admin::BaseController
      helper_method :taxjar_tax_category_option

      def edit
        if ENV["TAXJAR_API_KEY"].blank?
          flash[:error] = "You must provide a TaxJar API token to use this extension."
          render "edit_no_api_key"
        else
          @configuration = SuperGood::SolidusTaxjar.configuration
          @nexus_regions = cached_api.nexus_regions || []
          @tax_categories = cached_tax_categories
        end
      end

      def update
        configuration_update if params[:super_good_solidus_taxjar_configuration]
        tax_category_update if params[:tax_category]
        redirect_back(fallback_location: spree.admin_taxjar_settings_path)
      end

      def sync_nexus_regions
        api_sync do
          cached_api.nexus_regions(refresh: true)
          flash[:success] = "Updated with new Nexus Regions"
        end
      end

      def sync_tax_categories
        api_sync do
          cached_tax_categories
          flash[:success] = "Updated with new tax categories"
        end
      end

      private

      def cached_api
        SuperGood::SolidusTaxjar::CachedApi.new
      end

      def configuration_params
        params_hash = params.require(:super_good_solidus_taxjar_configuration).permit(:preferred_reporting_enabled, :preferred_reporting_enabled_at_integer)
        {
          preferred_reporting_enabled_at_integer: params_hash[:preferred_reporting_enabled] == "1" ? DateTime.now.to_i : nil
        }
      end

      def tax_category_params
        params.require(:tax_category)
      end

      def api_sync
        begin
          yield
        rescue Taxjar::Error => exception
          flash[:error] = "Failed to complete request to TaxJar: #{exception.message}"
        end
        redirect_back(fallback_location: spree.admin_taxjar_settings_path)
      end

      def cached_tax_categories
        Rails.cache.fetch(
          :tax_categories,
          expires_in: 30.days
        ) { SuperGood::SolidusTaxjar.api.tax_categories }
      end

      def configuration_update
        if SuperGood::SolidusTaxjar.configuration.update(configuration_params)
          flash[:success] = "TaxJar settings updated!"
        else
          flash[:alert] = "Failed to update settings!"
        end
      end

      def tax_category_update
        if Spree::TaxCategory.find(tax_category_params[:id]).update(tax_code: params[:tax_code_id])
          flash[:success] = "Tax category #{tax_category_params[:name]} tax code updated with #{params[:tax_code_id]}!"
        else
          flash[:alert] = "Failed to update tax category #{tax_category_params[:name]}!"
        end
      end

      def taxjar_tax_category_option(tax_code)
        selected_tax_category = @tax_categories.detect{|taxjar_tax_category| taxjar_tax_category.product_tax_code == tax_code}
        return unless selected_tax_category
        ["#{selected_tax_category.name} (#{selected_tax_category.product_tax_code})", selected_tax_category.product_tax_code]
      end
    end
  end
end
