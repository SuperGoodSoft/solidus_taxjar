require "spec_helper"

RSpec.describe SuperGood::SolidusTaxjar::Addresses do
  describe "#normalize" do
    subject { described_class.new(api: dummy_api).normalize(spree_address) }

    let(:spree_address) {
      create(
        :address,
        address1: "475 North Beverly Drive",
        city: "Los Angeles",
        country: country_us,
        first_name: "Chuck",
        last_name: "Schuldiner",
        phone: "1-250-555-4444",
        state: state_california,
        zipcode: "90210"
      )
    }

    let(:country_us) {
      Spree::Country.create!(
        iso3: "USA",
        iso: "US",
        iso_name: "UNITED STATES",
        name: "United States",
        numcode: 840,
        states_required: true
      )
    }

    let(:state_california) {
      Spree::State.create!(
        abbr: "CA",
        country: country_us,
        name: "California"
      )
    }

    let(:dummy_api) {
      instance_double ::SuperGood::SolidusTaxjar::Api
    }

    context "when there are no possibilities for the address" do
      before do
        allow(dummy_api)
          .to receive(:validate_spree_address)
          .with(spree_address)
          .and_raise(Taxjar::Error::NotFound)
      end

      it { is_expected.to be_nil }
    end

    context "when there is one possibility for the address" do
      before do
        allow(dummy_api)
          .to receive(:validate_spree_address)
          .with(spree_address)
          .and_return(results)
      end

      let(:results) {
        [
          Taxjar::Address.new(
            country: "US",
            state: "CA",
            zip: "90210-4606",
            city: "Beverly Hills",
            street: "475 N Beverly Dr"
          )
        ]
      }

      it "returns a sanitized address" do
        expect(subject).to eq(
          build(
            :address,
            address1: "475 N Beverly Dr",
            city: "Beverly Hills",
            country: country_us,
            first_name: "Chuck",
            last_name: "Schuldiner",
            phone: "1-250-555-4444",
            state: state_california,
            zipcode: "90210-4606"
          )
        )
      end
    end

    context "when there are multiple possibilities for the address" do
      before do
        allow(dummy_api)
          .to receive(:validate_spree_address)
          .with(spree_address)
          .and_return(results)
      end

      let(:results) {
        [
          Taxjar::Address.new(
            country: "US",
            state: "CA",
            zip: "90210-4606",
            city: "Beverly Hills",
            street: "475 N Beverly Dr"
          ),
          Taxjar::Address.new(
            country: "US",
            state: "AZ",
            zip: "90213-4606",
            city: "Beverly Hills",
            street: "475 N Beverly Dr"
          )
        ]
      }

      it "uses the first result to sanitize the addresses" do
        expect(subject).to eq(
          build(
            :address,
            address1: "475 N Beverly Dr",
            city: "Beverly Hills",
            country: country_us,
            first_name: "Chuck",
            last_name: "Schuldiner",
            phone: "1-250-555-4444",
            state: state_california,
            zipcode: "90210-4606"
          )
        )
      end
    end
  end

  describe "#normalize" do
    subject { described_class.new(api: dummy_api).possibilities(spree_address) }

    let(:spree_address) {
      create(
        :address,
        address1: "475 North Beverly Drive",
        city: "Los Angeles",
        country: country_us,
        first_name: "Chuck",
        last_name: "Schuldiner",
        phone: "1-250-555-4444",
        state: state_california,
        zipcode: "90210"
      )
    }

    let(:country_us) {
      Spree::Country.create!(
        iso3: "USA",
        iso: "US",
        iso_name: "UNITED STATES",
        name: "United States",
        numcode: 840,
        states_required: true
      )
    }

    let(:state_california) {
      Spree::State.create!(
        abbr: "CA",
        country: country_us,
        name: "California"
      )
    }

    let(:dummy_api) {
      instance_double ::SuperGood::SolidusTaxjar::Api
    }

    context "when there are no possibilities for the address" do
      before do
        allow(dummy_api)
          .to receive(:validate_spree_address)
          .with(spree_address)
          .and_raise(Taxjar::Error::NotFound)
      end

      it { is_expected.to be_empty }
    end

    context "when there is one possibility for the address" do
      before do
        allow(dummy_api)
          .to receive(:validate_spree_address)
          .with(spree_address)
          .and_return(results)
      end

      let(:results) {
        [
          Taxjar::Address.new(
            country: "US",
            state: "CA",
            zip: "90210-4606",
            city: "Beverly Hills",
            street: "475 N Beverly Dr"
          )
        ]
      }

      it "returns the possibilities" do
        expect(subject).to eq([
          build(
            :address,
            address1: "475 N Beverly Dr",
            city: "Beverly Hills",
            country: country_us,
            first_name: "Chuck",
            last_name: "Schuldiner",
            phone: "1-250-555-4444",
            state: state_california,
            zipcode: "90210-4606"
          )
        ])
      end
    end

    context "when there are multiple possibilities for the address" do
      before do
        allow(dummy_api)
          .to receive(:validate_spree_address)
          .with(spree_address)
          .and_return(results)
      end

      let(:results) {
        [
          Taxjar::Address.new(
            country: "US",
            state: "CA",
            zip: "90210-4606",
            city: "Beverly Hills",
            street: "475 N Beverly Dr"
          ),
          Taxjar::Address.new(
            country: "US",
            state: "AZ",
            zip: "90213-1234",
            city: "Phoenix",
            street: "473 N Beverly Dr"
          )
        ]
      }

      let!(:state_arizona) {
        Spree::State.create!(
          abbr: "AZ",
          country: country_us,
          name: "Arizona"
        )
      }

      it "returns all the possibilities" do
        expect(subject).to eq([
          build(
            :address,
            address1: "475 N Beverly Dr",
            city: "Beverly Hills",
            country: country_us,
            first_name: "Chuck",
            last_name: "Schuldiner",
            phone: "1-250-555-4444",
            state: state_california,
            zipcode: "90210-4606"
          ),
          build(
            :address,
            address1: "473 N Beverly Dr",
            city: "Phoenix",
            country: country_us,
            first_name: "Chuck",
            last_name: "Schuldiner",
            phone: "1-250-555-4444",
            state: state_arizona,
            zipcode: "90213-1234"
          )
        ])
      end
    end
  end
end
