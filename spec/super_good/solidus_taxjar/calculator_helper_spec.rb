require "spec_helper"

RSpec.describe SuperGood::SolidusTaxjar::CalculatorHelper do
  class TestProxy
    extend SuperGood::SolidusTaxjar::CalculatorHelper
  end

  describe "#incomplete_address?" do
    subject { TestProxy.incomplete_address?(address) }

    context "with a missing city" do
      let(:address) { build :address, city: nil }
      it { is_expected.to eq(true) }
    end

    context "with a missing address1" do
      let(:address) { build :address, address1: nil }
      it { is_expected.to eq(true) }
    end

    context "with a missing zipcode" do
      let(:address) { build :address, zipcode: nil }
      it { is_expected.to eq(true) }
    end

    context "with a missing state in CA" do
      let(:address) { build :address, country_iso_code: "CA", state: nil }
      it { is_expected.to eq(true) }
    end

    context "with a missing state in US" do
      let(:address) { build :address, country_iso_code: "US", state: nil }
      it { is_expected.to eq(true) }
    end

    context "with a missing state in DE" do
      let(:address) { build :address, country_iso_code: "DE", state: nil }
      it { is_expected.to eq(false) }
    end
  end

  describe "#state_required?" do
    subject { TestProxy.state_required?(country) }

    context "when the address' country is Canada" do
      let(:country) { Spree::Country.new(iso: "CA") }
      it { is_expected.to eq(true) }
    end

    context "when the address' country is the USA" do
      let(:country) { Spree::Country.new(iso: "US") }
      it { is_expected.to eq(true) }
    end

    context "when the address' country is neither Canada nor the USA" do
      let(:country) { Spree::Country.new(iso: "FR") }
      it { is_expected.to eq(false) }
    end
  end

  describe "#taxable_address?" do
    subject { TestProxy.taxable_address?(address) }

    let(:configuration_class) { double }

    before do
      allow(SuperGood::SolidusTaxjar)
        .to receive(:taxable_address_check)
        .and_return(configuration_class)
      allow(configuration_class).to receive(:call)
        .and_return(taxable_address)
    end

    context "when taxable address check returns false" do
      let(:taxable_address) { false }
      let(:address) do
        create :address, name: "Canada", country_iso_code: "CA"
      end

      it { is_expected.to be_falsey }
    end

    context "when taxable address check returns true" do
      let(:taxable_address) { true }

      context "with non-US address" do
        let(:address) do
          create :address, name: "Canada", country_iso_code: "CA"
        end

        it { is_expected.to be_truthy }
      end

      context "with US address", :vcr do
        let(:usa) { create :country, iso: "US", name: "United States" }

        # This test expects a TaxJar account to have nexus in California.
        #
        context "when the address is within a nexus region" do
          let(:address) {
            create :address,
              state: create(:state, abbr: "CA", country: usa, name: "Cali!"),
              country: usa,
              zipcode: "94704"
          }

          it { is_expected.to eq true }
        end

        # This test expects a TaxJar account to *not* have nexus in Alabama.
        #
        context "when the address is not within a nexus region" do
          let(:address) {
            create :address,
              state: create(:state, abbr: "AL", country: usa, name: "Alabama"),
              country: usa,
              zipcode: "35006"
          }

          it { is_expected.to eq false }
        end
      end
    end
  end
end
