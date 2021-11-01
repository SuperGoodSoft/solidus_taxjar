require 'spec_helper'

RSpec.feature 'Checkout', js: true do
  let!(:store) { create(:store, default: true) }
  let!(:country) { create(:country, states_required: true) }
  let!(:state) { create(:state, country: country) }
  let!(:shipping_method) { create(:shipping_method) }
  let!(:stock_location) { create(:stock_location) }
  let!(:mug) { create(:product, name: "RoR Mug") }
  let!(:payment_method) { create(:check_payment_method) }
  let!(:zone) { create(:zone) }

  def fill_in_credit_card(number: "4111 1111 1111 1111")
    fill_in "Name on card", with: 'Mary Doe'
    fill_in_with_force "Card Number", with: number
    fill_in_with_force "Expiration", with: "12 / 24"
    fill_in "Card Code", with: "123"
  end

  def fill_in_address
    address = "order_bill_address_attributes"
    fill_in "#{address}_name", with: "Ryan Bigg"
    fill_in "#{address}_address1", with: "143 Swan Street"
    fill_in "#{address}_city", with: "Richmond"
    select "United States of America", from: "#{address}_country_id"
    select "Alabama", from: "#{address}_state_id"
    fill_in "#{address}_zipcode", with: "12345"
    fill_in "#{address}_phone", with: "(555) 555-5555"
  end

  def add_mug_to_cart
    visit spree.root_path
    click_link mug.name
    click_button "add-to-cart-button"
  end

  context "full checkout" do
    it "does not break the per-item shipping method calculator", js: true do
      add_mug_to_cart
      click_button "Checkout"

      fill_in "order_email", with: "test@example.com"
      click_on "Continue"
      binding.pry
    end
  end
end
