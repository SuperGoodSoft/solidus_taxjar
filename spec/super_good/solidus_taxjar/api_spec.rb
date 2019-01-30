require 'spec_helper'

RSpec.describe SuperGood::SolidusTaxJar::API do
  describe "#tax_for" do
    subject { api.tax_for order }

    let(:api) { described_class.new(taxjar_client: dummy_client) }
    let(:dummy_client) { instance_double ::Taxjar::Client }
    let(:order) { Spree::Order.new }

    before do
      allow(SuperGood::SolidusTaxJar::APIParams)
        .to receive(:order_params)
        .with(order)
        .and_return({ order: "params" })

      allow(dummy_client)
        .to receive(:tax_for_order)
        .with({ order: "params" })
        .and_return({ some_kind_of: "response" })
    end

    it { is_expected.to eq({ some_kind_of: "response" }) }
  end

  describe "#tax_rates_for" do
    subject { api.tax_rates_for address }

    let(:api) do
      described_class.new(taxjar_client: dummy_client)
    end

    let(:dummy_client) do
      instance_double ::Taxjar::Client
    end

    let(:address) do
      Spree::Address.create!(
        country: country_us,
        state: state_california,
        zipcode: "90210",
        city: "Los Angeles",
        address1: "475 N Beverly Dr",

        first_name: "Chuck",
        last_name: "Schuldiner",
        phone: "1-250-555-4444"
      )
    end

    let(:country_us) do
      Spree::Country.create!(
        iso_name: "UNITED STATES",
        iso: "US",
        iso3: "USA",
        name: "United States",
        numcode: 840,
        states_required: true
      )
    end

    let(:state_california) do
      Spree::State.create!(
        country: country_us,
        name: "California",
        abbr: "CA"
      )
    end

    before do
      allow(dummy_client).to receive(:rates_for_location).with(
        "90210",
        country: "US",
        city: "Los Angeles",
        state: "CA",
        street: "475 N Beverly Dr"
      ).and_return({ some_kind_of: "response" })
    end

    it { is_expected.to eq({ some_kind_of: "response" }) }
  end
end
