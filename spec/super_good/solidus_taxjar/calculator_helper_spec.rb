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
end
