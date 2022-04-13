require "spec_helper"

RSpec.describe 'Admin TaxJar Settings', :vcr, type: :request do
  extend Spree::TestingSupport::AuthorizationHelpers::Request
  stub_authorization!
  let(:dummy_api) { instance_double(SuperGood::SolidusTaxjar::Api) }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "GET #sync_nexus_regions" do
    subject { get spree.admin_taxjar_settings_sync_nexus_regions_path }

    context "Taxjar API token is set" do
      let(:api_token) { ENV.fetch("TAXJAR_API_KEY", "fake_token") }

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("TAXJAR_API_KEY").and_return(api_token)
        allow(SuperGood::SolidusTaxjar).to receive(:api).and_return(dummy_api)
        allow(dummy_api).to receive(:nexus_regions).and_return([])
      end

      it "makes a request for the nexus regions" do
        subject
        expect(dummy_api).to have_received(:nexus_regions)
      end

      it "redirects back to TaxJar settings" do
        subject
        expect(response).to redirect_to "/admin/taxjar_settings"
      end

      context "Taxjar call is successful" do
        it "flashes a success alert" do
          subject

          expect(flash[:success]).to eq("Updated with new Nexus Regions")
        end
      end

      context "Taxjar responds with an error" do
        before do
          allow(dummy_api).to receive(:nexus_regions).and_raise(Taxjar::Error, "fake error message")
        end

        it "flashes an error alert" do
          subject

          expect(flash[:error]).to eq("Failed to complete request to TaxJar: fake error message")
        end
      end
    end

    context "Taxjar API token is not set" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("TAXJAR_API_KEY").and_return(nil)
      end

      it "doesn't make a request for the nexus regions" do
        subject
        expect(flash[:error]).to eq "Failed to complete request to TaxJar: Not authorized for route 'GET /v2/nexus/regions'"
      end
    end
  end

  describe "GET #sync_tax_categories" do
    subject { get spree.admin_taxjar_settings_sync_tax_categories_path }

    context "Taxjar API token is set" do
      let(:api_token) { ENV.fetch("TAXJAR_API_KEY", "fake_token") }

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("TAXJAR_API_KEY").and_return(api_token)
        allow(SuperGood::SolidusTaxjar).to receive(:api).and_return(dummy_api)
        allow(dummy_api).to receive(:tax_categories).and_return([])
      end

      it "makes a request for the tax categories" do
        subject
        expect(dummy_api).to have_received(:tax_categories)
      end

      it "redirects back to TaxJar settings" do
        subject
        expect(response).to redirect_to "/admin/taxjar_settings"
      end

      context "Taxjar call is successful" do
        it "flashes a success alert" do
          subject

          expect(flash[:success]).to eq("Updated with new tax categories")
        end
      end

      context "Taxjar responds with an error" do
        before do
          allow(dummy_api).to receive(:tax_categories).and_raise(Taxjar::Error, "fake error message")
        end

        it "flashes an error alert" do
          subject

          expect(flash[:error]).to eq("Failed to complete request to TaxJar: fake error message")
        end
      end
    end

    context "Taxjar API token is not set" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("TAXJAR_API_KEY").and_return(nil)
      end

      it "doesn't make a request for the tax categories" do
        subject
        expect(flash[:error]).to eq "Failed to complete request to TaxJar: Not authorized for route 'GET /v2/categories'"
      end
    end
  end

  describe "PUT #update" do
    subject { put spree.admin_taxjar_settings_path params: params }

    context "updating TaxJar settings" do
      let(:taxjar_configuration) { create :taxjar_configuration, preferred_reporting_enabled: false }
      let(:params) { {super_good_solidus_taxjar_configuration: {"preferred_reporting_enabled" => true}} }

      it "redirects back to TaxJar settings" do
        subject
        expect(response).to redirect_to "/admin/taxjar_settings"
      end

      it "shows a flash message" do
        subject
        expect(flash[:success]).to eq "TaxJar settings updated!"
      end

      it "updates the taxjar settings" do
        expect { subject }.to change { taxjar_configuration.reload.preferred_reporting_enabled }.from(false).to(true)
      end

      context "update fails" do
        before do
          allow(SuperGood::SolidusTaxjar).to receive(:configuration).and_return(taxjar_configuration)
          allow(taxjar_configuration).to receive(:update).and_return(false)
        end

        it "redirects back to TaxJar settings" do
          subject
          expect(response).to redirect_to "/admin/taxjar_settings"
        end

        it "shows a flash message" do
          subject
          expect(flash[:alert]).to eq "Failed to update settings!"
        end
      end
    end

    context "updating a tax category" do
      let(:tax_category) { create(:tax_category, name: "Bibles", tax_code: "123") }
      let(:params) { {tax_category: {name: "Bibles", tax_code: "123", id: tax_category.id}, tax_code_id: "81121"} }

      it "updates the tax code" do
        expect { subject }.to change { tax_category.reload.tax_code }.from("123").to("81121")
      end
    end
  end
end
