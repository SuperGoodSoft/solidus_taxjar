require "spec_helper"

RSpec.describe ::SuperGood::SolidusTaxjar::TaxCalculator do
  describe "#calculate" do
    subject { calculator.calculate }

    let(:calculator) { described_class.new(order, api: dummy_api) }

    let(:dummy_api) do
      instance_double ::SuperGood::SolidusTaxjar::API
    end

    let(:order) do
      ::Spree::Order.new(
        id: 10,
        store: store,
        ship_address: address,
        line_items: line_items,
        shipments: [
          boring_shipment,
          shipment_with_adjustment,
          shipment_with_existing_tax
        ]
      )
    end

    let(:line_items) { [::Spree::LineItem.new(id: 33)] }

    let(:boring_shipment) do
      ::Spree::Shipment.new(id: 1, cost: 7)
    end

    let(:shipment_with_adjustment) do
      ::Spree::Shipment.new(
        id: 2,
        cost: 20,
        adjustments: [
          ::Spree::Adjustment.new(amount: -7)
        ]
      )
    end

    let(:shipment_with_existing_tax) do
      ::Spree::Shipment.new(
        id: 3,
        cost: 10,
        additional_tax_total: 3,
        adjustments: [
          ::Spree::Adjustment.new(
            amount: 3,
            source_type: "Spree::TaxRate"
          )
        ]
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

    context "when the order has an incomplete tax address" do
      let(:address) do
        ::Spree::Address.new(
          first_name: "Ronnie James",
          zipcode: nil,
          address1: nil,
          city: "Beverly Hills",
          state_name: "California",
          country: ::Spree::Country.new(iso: "US")
        )
      end

      it "returns no taxes" do
        expect(subject.order_id).to eq order.id
        expect(subject.shipment_taxes).to be_empty
        expect(subject.line_item_taxes).to be_empty
      end
    end

    context "when the order has no tax address" do
      let(:address) { nil }

      it "returns no taxes" do
        expect(subject.order_id).to eq order.id
        expect(subject.shipment_taxes).to be_empty
        expect(subject.line_item_taxes).to be_empty
      end
    end

    context "when the order has no line items" do
      let(:address) do
        ::Spree::Address.new(
          first_name: "Ronnie James",
          zipcode: "90210",
          address1: "9900 Wilshire Blvd",
          city: "Beverly Hills",
          state_name: "California",
          country: ::Spree::Country.new(iso: "US")
        )
      end

      let(:line_items) { [] }

      it "returns no taxes" do
        expect(subject.order_id).to eq order.id
        expect(subject.shipment_taxes).to be_empty
        expect(subject.line_item_taxes).to be_empty
      end
    end

    context "when the API encounters an error" do
      let(:address) do
        ::Spree::Address.new(
          first_name: "Ronnie James",
          zipcode: "90210",
          address1: "9900 Wilshire Blvd",
          city: "Beverly Hills",
          state_name: "California",
          country: ::Spree::Country.new(iso: "US")
        )
      end

      before do
        allow(dummy_api).to receive(:tax_for).with(order).and_raise("A bad thing happened.")
      end

      it "calls the configured error handler" do
        expect(SuperGood::SolidusTaxjar.exception_handler).to receive(:call) do |e|
          expect(e).to be_a StandardError
          expect(e.message).to eq "A bad thing happened."
        end

        subject
      end

      it "returns no taxes" do
        expect(subject.order_id).to eq order.id
        expect(subject.shipment_taxes).to be_empty
        expect(subject.line_item_taxes).to be_empty
      end
    end

    context "when the order has a non-empty tax address" do
      let(:address) do
        ::Spree::Address.new(
          first_name: "Ronnie James",
          zipcode: "90210",
          address1: "9900 Wilshire Blvd",
          city: "Beverly Hills",
          state_name: "California",
          country: ::Spree::Country.new(iso: "US")
        )
      end

      before do
        allow(dummy_api).to receive(:tax_for).with(order).and_return(
          instance_double(
            ::Taxjar::Tax,
            breakdown: breakdown
          )
        )
      end

      context "and there is tax" do
        let!(:tax_rate) do
          ::Spree::TaxRate.create!(
            name: "Sales Tax",
            amount: 0.5,
            calculator: ::Spree::Calculator.new
          )
        end

        let(:breakdown) do
          instance_double ::Taxjar::Breakdown,
            line_items: [taxjar_line_item],
            shipping?: !!shipping_tax_breakdown,
            shipping: shipping_tax_breakdown
        end

        let(:taxjar_line_item) do
          instance_double ::Taxjar::BreakdownLineItem, id: "33", tax_collectable: 6.66
        end

        let(:shipping_tax_breakdown) { nil }

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

        context "with custom line item tax labels" do
          before do
            allow(SuperGood::SolidusTaxjar.line_item_tax_label_maker)
              .to receive(:call)
              .with(taxjar_line_item, line_items.first)
              .and_return("Space Tax")
          end

          it "applies those labels" do
            expect(subject.line_item_taxes.length).to eq 1
            expect(subject.line_item_taxes.first.label).to eq "Space Tax"
          end
        end

        context "but the taxable address check returns false" do
          before do
            allow(SuperGood::SolidusTaxjar.taxable_address_check)
              .to receive(:call).with(address)
              .and_return(false)
          end

          it "returns no taxes" do
            expect(subject.order_id).to eq order.id
            expect(subject.shipment_taxes).to be_empty
            expect(subject.line_item_taxes).to be_empty
          end
        end

        context "but the taxable order check returns false" do
          before do
            allow(SuperGood::SolidusTaxjar.taxable_order_check)
              .to receive(:call).with(order)
              .and_return(false)
          end

          it "returns no taxes" do
            expect(subject.order_id).to eq order.id
            expect(subject.shipment_taxes).to be_empty
            expect(subject.line_item_taxes).to be_empty
          end
        end

        context "when there are shipping taxes" do
          let(:shipping_tax_breakdown) do
            instance_double ::Taxjar::Shipping, tax_collectable: 10.00
          end

          it "returns the shipping taxes" do
            shipment_taxes = subject.shipment_taxes
            expect(shipment_taxes.length).to eq 3

            aggregate_failures do
              expect(shipment_taxes[0].item_id).to eq 1
              expect(shipment_taxes[0].label).to eq "Sales Tax"
              expect(shipment_taxes[0].tax_rate).to eq tax_rate
              expect(shipment_taxes[0].amount).to eq 2.33
              expect(shipment_taxes[0].included_in_price).to eq false

              expect(shipment_taxes[1].item_id).to eq 2
              expect(shipment_taxes[1].label).to eq "Sales Tax"
              expect(shipment_taxes[1].tax_rate).to eq tax_rate
              expect(shipment_taxes[1].amount).to eq 4.33
              expect(shipment_taxes[1].included_in_price).to eq false

              expect(shipment_taxes[2].item_id).to eq 3
              expect(shipment_taxes[2].label).to eq "Sales Tax"
              expect(shipment_taxes[2].tax_rate).to eq tax_rate
              expect(shipment_taxes[2].amount).to eq 3.34
              expect(shipment_taxes[2].included_in_price).to eq false
            end
          end

          context "with custom shipping tax labels" do
            before do
              allow(SuperGood::SolidusTaxjar.shipping_tax_label_maker).to receive(:call)
                .and_return("Magic Tax", "Spicy Tax", "Vegetable Tax")
            end

            it "applies those labels" do
              shipment_taxes = subject.shipment_taxes
              expect(shipment_taxes.length).to eq 3

              aggregate_failures do
                expect(shipment_taxes[0].label).to eq "Magic Tax"
                expect(shipment_taxes[1].label).to eq "Spicy Tax"
                expect(shipment_taxes[2].label).to eq "Vegetable Tax"
              end
            end
          end
        end

        context "when test_mode is set" do
          before { SuperGood::SolidusTaxjar.test_mode = true }
          after { SuperGood::SolidusTaxjar.test_mode = false }

          it "returns no taxes" do
            expect(subject.order_id).to eq order.id
            expect(subject.shipment_taxes).to be_empty
            expect(subject.line_item_taxes).to be_empty
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
