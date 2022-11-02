require 'spec_helper'

RSpec.feature 'Reporting orders to TaxJar', js: true, vcr: true do
  stub_authorization!

  background do
    create :store, default: true
    create :taxjar_configuration, :reporting_enabled
  end

  let!(:order) { create :order_ready_to_ship }

  scenario "shipping a complete and paid order", vcr: { allow_unused_http_interactions: false } do
    visit spree.edit_admin_order_path(order)
    perform_enqueued_jobs do
      wait_for_order_information_to_load
      click_on "Ship"
      expect(page).to have_content("Shipped package from")
    end

    expect(page).to have_text("Reported to TaxJar at: #{Date.current.strftime("%B %d, %Y")}", normalize_ws: true)
    expect(page).to have_text("TaxJar Sync: Success", normalize_ws: true)
  end

  def wait_for_order_information_to_load
    expect(page).not_to have_content("Loading")
  end
end
