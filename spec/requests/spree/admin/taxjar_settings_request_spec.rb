require 'spec_helper'

RSpec.describe 'Admin TaxJar Settings', :type => :request do
  # https://github.com/solidusio-contrib/solidus_subscriptions/blob/master/spec/controllers/spree/admin/subscriptions_controller_spec.rb
  extend Spree::TestingSupport::AuthorizationHelpers::Request
  stub_authorization!

  before do
    ActionController::Base.allow_forgery_protection = false
  end

  after do
    ActionController::Base.allow_forgery_protection = true
  end

  describe "PUT #update" do
    subject { put spree.admin_taxjar_settings_path }

    it "redirects back to TaxJar settings" do
      subject
      expect(response).to redirect_to "/admin/taxjar_settings"
    end

    it "shows a flash message" do
      subject
      expect(flash[:alert]).to eq "TaxJar settings updated!"
    end

    it "updates the taxjar settings" do
      settings_double = instance_double(SuperGood::SolidusTaxjar::Settings)
      expect(SuperGood::SolidusTaxjar::Settings).to receive(:find_or_create).and_return(settings_double)
      expect(settings_double).to receive(:update) do |properties_hash|
        expect(properties_hash[:reporting_enabled]).to eq "true"
      end
    end
  end
end
