require 'spec_helper'

RSpec.describe 'Admin TaxJar Settings', :type => :request do
  extend Spree::TestingSupport::AuthorizationHelpers::Request
  stub_authorization!

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
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
end
