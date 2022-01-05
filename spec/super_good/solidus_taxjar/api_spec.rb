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
    let(:order) { create :order, number: "R123" }

    let(:dummy_response) do
      instance_double(
        ::Taxjar::Order,
        transaction_id: "R123",
        transaction_date: "2015-05-15T00:00:00Z"
      )
    end

    before do
      allow(SuperGood::SolidusTaxjar::ApiParams)
        .to receive(:transaction_params)
        .with(order, "R123")
        .and_return({transaction: "params"})

      allow(dummy_client)
        .to receive(:create_order)
        .with({transaction: "params"})
        .and_return(dummy_response)
    end

    it { is_expected.to eq(dummy_response) }

    it "creates an `OrderTransaction` for the order" do
      expect { subject }
        .to change { order.taxjar_order_transactions.count }
        .from(0)
        .to(1)
    end

    it "sets `transaction_id` and `transaction_date` on the order transaction" do
      subject
      expect(order.taxjar_order_transactions.first)
        .to have_attributes(
          transaction_id: "R123",
          transaction_date: DateTime.new(2015, 5, 15, 0, 0, 0, "+0")
        )
    end

    context "when the API call to create the transaction fails" do
      before do
        allow(dummy_client).to receive(:create_order).and_raise(Taxjar::Error)
      end

      it "does not create an `OrderTransaction` for the order" do
        expect { subject }.to raise_error(Taxjar::Error)
        expect(order.taxjar_order_transactions.count).to be_zero
      end
    end
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

  describe "#delete_transaction_for" do
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

  describe "#show_latest_transaction_for" do
    subject { api.show_latest_transaction_for order }

    let(:api) { described_class.new(taxjar_client: dummy_client) }
    let(:dummy_client) { instance_double ::Taxjar::Client }
    let(:order) { Spree::Order.new(number: "R111222333") }

    context "with a persisted order transaction" do
      before do
        create(
          :taxjar_order_transaction,
          order: order,
          transaction_id: "R111222333-42"
        )
      end

      let(:order) { create(:order, number: "R111222333") }

      it "uses the persisted transaction_id to fetch the TaxJar transaction" do
        expect(dummy_client)
          .to receive(:show_order)
          .with("R111222333-42")
          .and_return({some_kind_of: "response"})
        expect(subject).to eq({some_kind_of: "response"})
      end
    end

    context "without a persisted order transaction" do
      it "raises an exception" do
        expect { subject }.to raise_error(
          NotImplementedError,
          "No latest TaxJar order transaction for #{order.number}. "       \
          "Backfilling TaxJar transaction orders from Solidus is not yet " \
          "implemented."
        )
      end
    end
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

  describe "#create_refund_transaction_for" do
    subject { api.create_refund_transaction_for order }

    let(:api) { described_class.new(taxjar_client: dummy_client) }
    let(:dummy_client) { instance_double ::Taxjar::Client }
    let(:order) { create(:order_ready_to_ship, number: "R111222333") }

    let(:taxjar_order) {
      Taxjar::Order.new(
        amount: 20,
        sales_tax: 2,
        shipping: 5
      )
    }

    before do
      allow(dummy_client)
        .to receive(:show_order)
        .with("R111222333-10")
        .and_return(taxjar_order)

      allow(SuperGood::SolidusTaxjar::ApiParams)
        .to receive(:refund_transaction_params)
        .with(order, taxjar_order)
        .and_return({refund_transaction: "params"})

      allow(dummy_client)
        .to receive(:create_refund)
        .with({refund_transaction: "params"})
        .and_return({some_kind_of: "response"})
    end

    context "when no order transaction has been persisted" do
      it "raises an exception" do
        expect { subject }.to raise_error(
          NotImplementedError,
          "No latest TaxJar order transaction for #{order.number}. "       \
          "Backfilling TaxJar transaction orders from Solidus is not yet " \
          "implemented."
        )
      end
    end

    context "when an order transaction has been persisted" do
      before do
        create(
          :taxjar_order_transaction,
          order: order,
          transaction_id: "R111222333-10"
        )
      end

      it "requests the latest transaction from TaxJar" do
        expect(dummy_client).to receive(:show_order).with("R111222333-10")

        subject
      end

      it { is_expected.to eq({some_kind_of: "response"}) }
    end
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
