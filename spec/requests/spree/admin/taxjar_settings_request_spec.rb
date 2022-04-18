require 'spec_helper'

RSpec.describe 'Admin TaxJar Settings', :vcr, :type => :request do
  extend Spree::TestingSupport::AuthorizationHelpers::Request
  stub_authorization!

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "GET #sync_nexus_regions" do
    subject { get spree.admin_taxjar_settings_sync_nexus_regions_path }

    let(:dummy_api) { instance_double(SuperGood::SolidusTaxjar::Api) }

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

          expect(flash[:error]).to eq("fake error message")
        end
      end
    end

    context "Taxjar API token is not set" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("TAXJAR_API_KEY").and_return(nil)
      end

      it "doesn't make a request for the nexus regions" do
        allow(SuperGood::SolidusTaxjar).to receive(:api).and_return(dummy_api)
        allow(dummy_api).to receive(:nexus_regions).and_return([])

        subject

        expect(dummy_api).to_not have_received(:nexus_regions)
      end
    end
  end

  describe "PUT #update" do
    subject { put spree.admin_taxjar_settings_path params:{ super_good_solidus_taxjar_configuration:{"preferred_reporting_enabled"=>true} }}

    let(:taxjar_configuration) { create :taxjar_configuration, preferred_reporting_enabled: false }

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

  describe "#backfill_transactions" do
    subject { post spree.admin_taxjar_settings_backfill_transactions_path }

    let(:order) { create(:shipped_order) }

    before do
      create(:tax_rate, name: "Sales Tax")
      # The order must be created **after** the TaxRate to have the correct totals
      order
    end

    it "shows a flash message" do
      subject
      expect(flash[:success]).to eq "Queued transaction backfill for 1 orders."
    end

    it "shows the backfilled orders" do
      subject
      expect(response.body).to include "Backfilled Orders"
      expect(response.body).to include order.number
    end
  end
end
