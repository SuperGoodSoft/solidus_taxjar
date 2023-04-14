require 'spec_helper'

RSpec.feature 'Reporting orders to TaxJar', js: true, vcr: { allow_unused_http_interactions: false } do
  stub_authorization!

  background do
    create :store, default: true
    create :taxjar_configuration, :reporting_enabled
  end

  let!(:order) do
    # FIXME: This factory is bad!
    create(:order_ready_to_ship).tap { |o| o.touch(:completed_at) }
  end

  scenario "shipping a complete and paid order" do
    visit spree.edit_admin_order_path(order)
    perform_enqueued_jobs do
      wait_for_order_information_to_load
      click_on "Ship"
      expect(page).to have_content("Shipped package from")
    end

    expect(page).to have_text("Reported to TaxJar at: #{Date.current.strftime("%B %d, %Y")}", normalize_ws: true)
    expect(page).to have_text("TaxJar Sync: Success", normalize_ws: true)
  end

  context "with an order with invalid zipcode" do
    let(:invalid_address) do
      create(:address, zipcode: 99999)
    end

    before do
      order.update!(ship_address: invalid_address)
    end

    scenario "retry of a previously failed transaction sync" do
      pending "retry feature is implemented"

      visit spree.edit_admin_order_path(order)

      perform_enqueued_jobs do
        wait_for_order_information_to_load
        click_on "Ship"
        expect(page).to have_content("Shipped package from")
      end

      within("#order_tab_summary") do
        expect(page).to have_text("TaxJar Sync: Error", normalize_ws: true)
        expect(page).to have_text("Retry")
      end
    end
  end

  def wait_for_order_information_to_load
    expect(page).not_to have_content("Loading")
  end
end
