require 'spec_helper'

RSpec.feature 'Reporting orders to TaxJar', js: true, vcr: { allow_unused_http_interactions: false } do
  stub_authorization!

  background do
    create :store, default: true
    create :taxjar_configuration, :reporting_enabled
  end

  let(:order) do
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

    let(:order) do
      # FIXME: This factory is bad!
      create(
        :order_ready_to_ship,
        ship_address: invalid_address
      ).tap do |order|
        order.touch(:completed_at)
        order.recalculate
        order.payments.first.update!(amount: 110)
      end
    end

    scenario "retry of a previously failed transaction sync" do
      visit spree.edit_admin_order_path(order)

      perform_enqueued_jobs do
        wait_for_order_information_to_load

        click_on "Ship"
        expect(page).to have_content("Shipped package from")
      end

      within("#order_tab_summary") do
        expect(page).to have_text("Reported to TaxJar at: -", normalize_ws: true)
        expect(page).to have_text("TaxJar Sync: Error", normalize_ws: true)

        click_on "TaxJar Sync History"
      end

      within("#content-header") do
        expect(page).to have_content("TaxJar Sync History")
      end

      within('#transaction_sync_logs') do
        expect(page).to have_content("Retry")
        click_on "Retry"
      end

      expect(page).to have_content("Queued transaction sync job")
    end
  end

  context "updating an order which was not reported due to failure" do
    let(:invalid_address) do
      create(:address, zipcode: 99999)
    end

    let(:order) do
      # FIXME: This factory is bad!
      create(
        :order_ready_to_ship,
        ship_address: invalid_address
      ).tap { |o| o.touch(:completed_at) }
    end

    before do
      # We need at least one reason before we can create a refund.
      create(:refund_reason, name: "Refund")
    end

    scenario "it reports the order instead of trying to replace it" do
      visit spree.edit_admin_order_path(order)

      perform_enqueued_jobs do
        wait_for_order_information_to_load
        click_on "Ship"
        expect(page).to have_content("Shipped package from")
      end

      within("#order_tab_summary") do
        expect(page).to have_text("Reported to TaxJar at: -", normalize_ws: true)
        expect(page).to have_text("TaxJar Sync: Error", normalize_ws: true)
      end

      # Update the order to fix the error with the address.
      within("ul.tabs") do
        click_on "Customer"
      end

      expect(page).to have_content("Shipping Address")

      within("div[data-hook=\"ship_address_wrapper\"]") do
        fill_in("Zip Code", with: "")
        fill_in("Zip Code", with: "11430")
      end

      perform_enqueued_jobs do
        click_on "Update"
      end

      expect(page).to have_content("Customer Details Updated")

      # To trigger reporting to TaxJar - by creating a refund to balance.
      within("ul.tabs") do
        click_on "Payments"
      end

      expect(page).to have_content("Balance Due: $9.77")

      click_on "New Payment"

      expect(page).to have_content("New Payment")

      click_on "Update"

      expect(page).to have_content("Payment has been successfully created!")

      click_icon "capture"

      expect(page).to have_content("Payment Updated")

      flush_enqueued_jobs

      page.refresh


      expect(page).to have_text("TaxJar Sync: Success", normalize_ws: true)
    end
  end

  def wait_for_order_information_to_load
    expect(page).not_to have_content("Loading")
  end
end
