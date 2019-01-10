require 'spec_helper'

RSpec.describe ::SuperGood::SolidusTaxJar::TaxCalculator do
  describe "#calculate" do
    subject { calculator.calculate }

    let(:calculator) { described_class.new(order, api: dummy_api) }

    let(:dummy_api) do
      instance_double ::SuperGood::SolidusTaxJar::API
    end

    let(:order) do
      ::Spree::Order.new(
        id: 10,
        store: store,
        ship_address: address
      )
    end

    let(:store) do
      ::Spree::Store.new(
        name: "Default Store",
        url: "https://store.example.com",
        code: "store",
        mail_from_address: "contact@example.com",
        cart_tax_country_iso: "US"
      )
    end

    context "when the order has an empty tax address" do
      let(:address) { nil }

      it "returns no taxes" do
        expect(subject.order_id).to eq order.id
        expect(subject.shipment_taxes).to be_empty
        expect(subject.line_item_taxes).to be_empty
      end
    end

    context "when the order has a non-empty tax address" do
      let(:address) { ::Spree::Address.new(first_name: "Ronnie James") }

      before do
        allow(dummy_api).to receive(:tax_for).with(order).and_return(
          instance_double(::Taxjar::Tax, breakdown: breakdown)
        )
      end

      context "and there is a breakdown" do
        let!(:tax_rate) do
          ::Spree::TaxRate.create!(
            name: "Sales Tax",
            amount: 0.5,
            calculator: ::Spree::Calculator.new
          )
        end

        let(:breakdown) do
          instance_double ::Taxjar::Breakdown, line_items: [taxjar_line_item]
        end

        let(:taxjar_line_item) do
          instance_double ::Taxjar::BreakdownLineItem, id: "33", tax_collectable: 6.66
        end

        it "returns the taxes" do
          expect(subject.order_id).to eq order.id
          expect(subject.shipment_taxes).to be_empty
          expect(subject.line_item_taxes.length).to eq 1

          item_tax = subject.line_item_taxes.first
          aggregate_failures do
            expect(item_tax.item_id).to eq 33
            expect(item_tax.label).to eq "Sales Tax"
            expect(item_tax.tax_rate).to eq tax_rate
            expect(item_tax.amount).to eq 6.66
            expect(item_tax.included_in_price).to eq false
          end
        end
      end

      context "and there is not a breakdown" do
        let(:breakdown) { nil }

        it "returns no taxes" do
          expect(subject.order_id).to eq order.id
          expect(subject.shipment_taxes).to be_empty
          expect(subject.line_item_taxes).to be_empty
        end
      end
    end
  end
end
