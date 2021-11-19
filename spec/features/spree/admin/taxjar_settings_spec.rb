require 'spec_helper'

RSpec.feature 'Admin TaxJar Settings', js: true do
  stub_authorization!

  background do
    create :store, default: true
  end

  describe "Taxjar settings tab" do
    let(:api_token) { "token" }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("TAXJAR_API_KEY").and_return(api_token)

      visit "/admin"
      click_on "Settings"
      expect(page).to have_content("Taxes")
      click_on "Taxes"
      expect(page).to have_content("TaxJar Settings")
      click_on "TaxJar Settings"
    end

    context "Taxjar reporting is enabled" do
      it "shows that reporting is enabled" do

        expect(page).to have_content("Transaction Sync")
        expect(page).to have_select("reporting_enabled", selected: "No")
        expect(page).to have_content("Sync orders and refund with TaxJar for automated sales tax reporting and filing. Complete and closed transactions sync automatically on update.")

        select "Yes", from: "reporting_enabled"
        click_on "Save"
        visit current_path
        expect(page).to have_select("reporting_enabled", selected: "Yes")
      end
    end

    context "Taxjar API token is set" do
      it "shows a blank settings page" do
        expect(page).not_to have_content "You must provide a TaxJar API token"
      end
    end

    context "Taxjar API token isn't set" do
      let(:api_token) { nil }

      it "shows a descriptive error message" do
        expect(page).to have_content "You must provide a TaxJar API token"

        expect(page).to have_link(href: "https://app.taxjar.com/api_sign_up")
        expect(page).to have_link(href: "https://support.taxjar.com/article/160-how-do-i-get-a-sales-tax-api-token")
      end
    end
  end
end
