require 'spec_helper'

RSpec.feature 'Checkout', js: true do
  let!(:country) { create(:country, states_required: true) }
  let!(:mug) { create(:product, name: "RoR Mug") }

  before do
    create(:store, default: true)
    create(:state, country: country, state_code: "CA")
    create(:shipping_method)
    create(:stock_location)
    create(:check_payment_method)
    create(:zone)
  end

  def fill_in_address
    # This order needs to be a taxable address in your TaxJar
    # account in order to actually be charged tax. This means
    # your account should have "nexus" in the state.
    address = "order_bill_address_attributes"
    fill_in "#{address}_name", with: "Ryan Bigg"
    fill_in "#{address}_address1", with: "450 Helen Ave"
    fill_in "#{address}_city", with: "Ontario"
    select "United States of America", from: "#{address}_country_id"
    select "California", from: "#{address}_state_id"
    fill_in "#{address}_zipcode", with: "91761"
    fill_in "#{address}_phone", with: "(555) 555-5555"
  end

  it "adds tax calculated by TaxJar to the order total", js: true, vcr: {cassette_name: "features/spree/admin/checkout", allow_playback_repeats: true, allow_unused_http_interactions: false} do
    visit spree.root_path

    click_link mug.name
    click_button "add-to-cart-button"

    click_button "Checkout"

    # Taxes are calculated by matching the line items returned in a tax response with the line items in the order by ID.
    # When this spec is run in conjuction with other specs that create line items, the generated line item ID for the
    # order becomes dynamic, while the line item ID in the cassette is static. We need to ensure these IDs always match,
    # so we fix the line item ID to match the ID in the cassette.
    Spree::Order.last.line_items.first.update!(id: 9999)

    fill_in "order_email", with: "test@example.com"
    click_on "Continue"

    expect(page).to have_content("BILLING ADDRESS")
    fill_in_address
    click_button "Save and Continue"

    expect(page).to have_content("DELIVERY")
    click_button "Save and Continue"

    # Check that the total on the page includes tax. Without tax, the total is $29.99.
    expect(page).to have_content("Order Total: $31.54")
  end
end
