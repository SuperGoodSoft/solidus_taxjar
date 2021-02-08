require 'spec_helper'

RSpec.feature 'Admin TaxJar Settings', js: true do
  stub_authorization!

  background do
    create :store, default: true
  end

  describe "Taxjar settings tab" do
    before do
      allow(ENV).to receive(:[]).and_return("")
      allow(ENV).to receive(:[]).with("TAXJAR_API_KEY").and_return(api_token)
    end

    context "Taxjar API token is set" do
      let(:api_token) { "token" }

      it "shows a blank settings page" do

        visit "/admin"
        click_on "Settings"
        expect(page).to have_content("Taxes")
        click_on "Taxes"
        expect(page).to have_content("TaxJar Settings")
        click_on "TaxJar Settings"
        expect(page).not_to have_content "You must provide a TaxJar API token"
      end
    end

    context "Taxjar API token isn't set" do
      let(:api_token) { nil }

      it "shows a descriptive error message" do
        visit "/admin"
        click_on "Settings"
        expect(page).to have_content("Taxes")
        click_on "Taxes"
        expect(page).to have_content("TaxJar Settings")
        click_on "TaxJar Settings"
        expect(page).to have_content "You must provide a TaxJar API token"
      end
    end
  end
end
