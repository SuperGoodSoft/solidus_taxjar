require 'spec_helper'

RSpec.feature 'Admin TaxJar Settings', js: true, vcr: true do
  stub_authorization!

  background do
    create :store, default: true
    create :tax_category, name: "Bibles", tax_code: "123"
  end

  describe "Taxjar settings tab" do
    let(:api_token) { ENV.fetch("TAXJAR_API_KEY", "fake_token") }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("TAXJAR_API_KEY").and_return(api_token)
      allow(SuperGood::SolidusTaxjar).to receive(:reporting_ui_enabled).and_return(true)
    end

    scenario "the user navigates to the TaxJar Settings" do
      visit "/admin"
      click_on "Settings"
      expect(page).to have_content("Taxes")
      click_on "Taxes"
      expect(page).to have_content("TaxJar Settings")
      click_on "TaxJar Settings"

      within('[data-hook="admin_settings_taxes_tabs"] > .active') do
        expect(page).to have_content("TaxJar Settings")
      end
      expect(page).to have_content("Transaction Sync")
    end

    context "Taxjar reporting is enabled" do
      it "shows that reporting is enabled" do
        visit "/admin/taxjar_settings/edit"

        expect(page).to have_content("Transaction Sync")
        expect(page).to have_field("Transaction Sync", checked: false)
        expect(page).to have_content("Sync orders and refund with TaxJar for automated sales tax reporting and filing. Complete and closed transactions sync automatically on update.")

        check "Transaction Sync"
        click_on "Update Configuration"
        expect(page).to have_content("TaxJar settings updated!")
        expect(page).to have_field("Transaction Sync", checked: true)
      end
    end

    context "Taxjar API token is set" do
      it "shows the settings page" do
        visit "/admin/taxjar_settings/edit"
        expect(page).not_to have_content "You must provide a TaxJar API token"
        expect(page).to have_content "Transaction Sync"
        expect(page).to have_content("Nexus Regions")
        expect(page).to have_link("Go to TaxJar to configure states", href: "https://app.taxjar.com/account#states")

        # We press the button to see the page refresh successfully.
        click_on "Sync Nexus Regions"
        expect(page).to have_content("Updated with new Nexus Regions")

        within "[data-hook='admin_taxjar_tax_categories_sync']" do
          expect(page).to have_content("123")
        end
        select2_no_label("Bibles (81121)", from: "Select New Tax Code")
        click_on "Update Tax Category"
        within "[data-hook='admin_taxjar_tax_categories_sync']" do
          expect(page).to_not have_content("123")
          expect(page).to have_content("Bibles (81121)")
        end
      end
    end

    context "Taxjar API token isn't set" do
      let(:api_token) { nil }

      it "shows a descriptive error message" do
        visit "/admin/taxjar_settings/edit"

        expect(page).to have_content "You must provide a TaxJar API token"

        expect(page).to have_link(href: "https://app.taxjar.com/api_sign_up")
        expect(page).to have_link(href: "https://support.taxjar.com/article/160-how-do-i-get-a-sales-tax-api-token")
      end

      it "doesn't show any other TaxJar features" do
        expect(page).not_to have_content("Transaction Sync")
        expect(page).not_to have_content("Nexus Regions")
      end
    end
  end
end
