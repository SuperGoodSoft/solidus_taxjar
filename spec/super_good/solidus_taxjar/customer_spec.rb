require "spec_helper"

RSpec.describe SuperGood::SolidusTaxjar::Customer do
  describe "validations" do
    let(:country_us) do
      Spree::Country.create!(
        iso3: "USA",
        iso: "US",
        iso_name: "UNITED STATES",
        name: "United States",
        numcode: 840,
        states_required: true
      )
    end

    let(:state_california) {
      Spree::State.create!(
        abbr: "CA",
        country: country_us,
        name: "California"
      )
    }

    let(:ship_address) do
      Spree::Address.create!(
        address1: "475 N Beverly Dr",
        city: "Los Angeles",
        country: country_us,
        first_name: "Chuck",
        last_name: "Schuldiner",
        phone: "1-250-555-4444",
        state: state_california,
        zipcode: "90210"
      )
    end

    let(:user) do
      ::Spree.user_class.new(id: 12345)
    end

    let(:taxjar_customer) do
      SuperGood::SolidusTaxjar::Customer.new(
        user: user,
        address: ship_address,
        tax_exemption_type: "wholesale",
        taxjar_exempt_regions: [
          SuperGood::SolidusTaxjar::ExemptRegion.new(state: state_california, approved: true),
        ],
        )
    end

    it "throws an error when a user a nil" do
      taxjar_customer.user = nil
      taxjar_customer.save
      expect(taxjar_customer).not_to be_valid
    end

    it "throws an error when an address a nil" do
      taxjar_customer.address = nil
      taxjar_customer.save
      expect(taxjar_customer).not_to be_valid
    end

    it "does not an error when all validations are present" do
      taxjar_customer.save
      expect(taxjar_customer).to be_valid
    end
  end
end