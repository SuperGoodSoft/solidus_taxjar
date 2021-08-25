require "spec_helper"

RSpec.describe SuperGood::SolidusTaxjar::Api do
  describe ".new" do
    subject { described_class.new }

    before do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("TAXJAR_API_KEY").and_return("taxjar_api_token")
    end

    it "sets the correct headers" do
      expect_any_instance_of(::Taxjar::Client).to receive(:set_api_config).with('headers', {
        'x-api-version' => '2020-08-07',
        'plugin' => 'supergoodsolidustaxjar'
      })
      subject
    end
  end

  describe ".default_taxjar_client" do
    subject { described_class.default_taxjar_client }

    before do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("TAXJAR_API_KEY").and_return("taxjar_api_token")
    end

    it "returns an instance of the TaxJar client" do
      expect(subject).to be_an_instance_of(::Taxjar::Client)
    end
  end


  describe "#tax_for" do
    subject { api.tax_for order }

    let(:api) { described_class.new(taxjar_client: dummy_client) }
    let(:dummy_client) { instance_double ::Taxjar::Client }
    let(:order) { Spree::Order.new }

    before do
      allow(SuperGood::SolidusTaxjar::ApiParams)
        .to receive(:order_params)
        .with(order)
        .and_return({order: "params"})

      allow(dummy_client)
        .to receive(:tax_for_order)
        .with({order: "params"})
        .and_return({some_kind_of: "response"})
    end

    it { is_expected.to eq({some_kind_of: "response"}) }
  end

  describe "tax_rate_for" do
    subject { api.tax_rate_for address }

    let(:api) { described_class.new(taxjar_client: dummy_client) }
    let(:dummy_client) { instance_double ::Taxjar::Client }
    let(:address) { Spree::Address.new }
    let(:tax_rate) { 0.04 }
    let(:response) { double(rate: tax_rate) }

    before do
      allow(SuperGood::SolidusTaxjar::ApiParams)
        .to receive(:tax_rate_address_params)
        .with(address)
        .and_return({address: "params"})

      allow(dummy_client)
        .to receive(:tax_for_order)
        .with({address: "params"})
        .and_return(response)
    end

    it { is_expected.to eq(tax_rate) }
  end

  describe "#tax_rates_for" do
    subject { api.tax_rates_for address }

    let(:api) { described_class.new(taxjar_client: dummy_client) }
    let(:dummy_client) { instance_double ::Taxjar::Client }
    let(:address) { Spree::Address.new }

    before do
      allow(SuperGood::SolidusTaxjar::ApiParams)
        .to receive(:address_params)
        .with(address)
        .and_return(["zipcode", {address: "params"}])

      allow(dummy_client)
        .to receive(:rates_for_location)
        .with("zipcode", {address: "params"})
        .and_return({some_kind_of: "response"})
    end

    it { is_expected.to eq({some_kind_of: "response"}) }
  end

  describe "#create_transaction_for" do
    subject { api.create_transaction_for order }

    let(:api) { described_class.new(taxjar_client: dummy_client) }
    let(:dummy_client) { instance_double ::Taxjar::Client }
    let(:order) { build_stubbed :order, number: "R123" }

    before do
      allow(SuperGood::SolidusTaxjar::ApiParams)
        .to receive(:transaction_params)
        .with(order, "R123")
        .and_return({transaction: "params"})

      allow(dummy_client)
        .to receive(:create_order)
        .with({transaction: "params"})
        .and_return({some_kind_of: "response"})
    end

    it { is_expected.to eq({some_kind_of: "response"}) }
  end

  describe "#update_transaction_for" do
    subject { api.update_transaction_for order }

    let(:api) { described_class.new(taxjar_client: dummy_client) }
    let(:dummy_client) { instance_double ::Taxjar::Client }
    let(:order) { Spree::Order.new }

    before do
      allow(SuperGood::SolidusTaxjar::ApiParams)
        .to receive(:transaction_params)
        .with(order)
        .and_return({transaction: "params"})

      allow(dummy_client)
        .to receive(:update_order)
        .with({transaction: "params"})
        .and_return({some_kind_of: "response"})
    end

    it { is_expected.to eq({some_kind_of: "response"}) }
  end

  describe "#update_transaction_for" do
    subject { api.delete_transaction_for order }

    let(:api) { described_class.new(taxjar_client: dummy_client) }
    let(:dummy_client) { instance_double ::Taxjar::Client }
    let(:order) { Spree::Order.new(number: "R111222333") }

    before do
      allow(dummy_client)
        .to receive(:delete_order)
        .with("R111222333")
        .and_return({some_kind_of: "response"})
    end

    it { is_expected.to eq({some_kind_of: "response"}) }
  end

  describe "#create_refund_for" do
    subject { api.create_refund_for reimbursement }

    let(:api) { described_class.new(taxjar_client: dummy_client) }
    let(:dummy_client) { instance_double ::Taxjar::Client }
    let(:reimbursement) { Spree::Reimbursement.new }

    before do
      allow(SuperGood::SolidusTaxjar::ApiParams)
        .to receive(:refund_params)
        .with(reimbursement)
        .and_return({refund: "params"})

      allow(dummy_client)
        .to receive(:create_refund)
        .with({refund: "params"})
        .and_return({some_kind_of: "response"})
    end

    it { is_expected.to eq({some_kind_of: "response"}) }
  end

  describe "#validate_spree_address" do
    subject { api.validate_spree_address spree_address }

    let(:api) { described_class.new(taxjar_client: dummy_client) }
    let(:dummy_client) { instance_double ::Taxjar::Client }
    let(:spree_address) { build :address }

    before do
      allow(SuperGood::SolidusTaxjar::ApiParams)
        .to receive(:validate_address_params)
        .with(spree_address)
        .and_return({address: "params"})

      allow(dummy_client)
        .to receive(:validate_address)
        .with({address: "params"})
        .and_return({some_kind_of: "response"})
    end

    it { is_expected.to eq({some_kind_of: "response"}) }
  end

  describe "#nexus_regions" do
    subject { api.nexus_regions }

    let(:api) { described_class.new(taxjar_client: dummy_client) }
    let(:dummy_client) { instance_double ::Taxjar::Client }

    before do
      allow(dummy_client)
        .to receive(:nexus_regions)
        .and_return({some_kind_of: "response"})
    end

    it { is_expected.to eq({some_kind_of: "response"}) }
  end
end
