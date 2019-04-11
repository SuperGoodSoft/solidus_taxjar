require 'spec_helper'

RSpec.describe SuperGood::SolidusTaxJar::APIParams do
  let(:order) do
    Spree::Order.create!(
      number: "R111222333",
      total: BigDecimal("123.45"),
      shipment_total: BigDecimal("3.01"),
      additional_tax_total: BigDecimal("9.87"),
      item_total: BigDecimal("28.00"),
      store: store,
      ship_address: ship_address,
      line_items: [line_item]
    ).tap do |order|
      order.update! completed_at: DateTime.new(2018, 3, 6, 12, 10, 33)
    end
  end

  let(:store) do
    Spree::Store.create!(
      name: "Default Store",
      url: "https://store.example.com",
      code: "store",
      mail_from_address: "contact@example.com",
      cart_tax_country_iso: "US"
    )
  end

  let(:ship_address) do
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

  let(:line_item) do
    Spree::LineItem.new(
      variant: variant,
      price: 10,
      quantity: 3,
      promo_total: -2,
      additional_tax_total: 4
    )
  end

  let(:variant) do
    Spree::Variant.create!(
      sku: "G00D-PR0DUCT",
      product: product,
      price: 10
    )
  end

  let(:product) do
    Spree::Product.create!(
      name: "Product Name",
      shipping_category: shipping_category,
      tax_category: tax_category,
      master: master_variant,
      variants: [master_variant]
    )
  end

  let(:shipping_category) do
    Spree::ShippingCategory.create!(name: "Default Category")
  end

  let(:tax_category) do
    Spree::TaxCategory.create!(
      name: "Default",
      is_default: true,
      tax_code: "A_GEN_TAX"
    )
  end

  let(:master_variant) do
    Spree::Variant.new(
      is_master: true,
      price: 10
    )
  end

  let(:reimbursement) do
    Spree::Reimbursement.new(
      order: order,
      total: 333.33,
      number: "RI123123123",
      return_items: [
        Spree::ReturnItem.new(additional_tax_total: 0.33),
        Spree::ReturnItem.new(additional_tax_total: 33.0)
      ]
    )
  end

  describe "#order_params" do
    subject { described_class.order_params(order) }

    it "returns params for fetching the tax for the order" do
      expect(subject).to eq(
        to_country: "US",
        to_zip: "90210",
        to_city: "Los Angeles",
        to_state: "CA",
        to_street: "475 N Beverly Dr",

        shipping: 3.01,

        line_items: [{
          id: order.line_items.first.id,
          quantity: 3,
          unit_price: 10.00,
          discount: 2.00,
          product_tax_code: "A_GEN_TAX"
        }]
      )
    end

    context "when the line item has zero quantity" do
      let(:line_item) do
        Spree::LineItem.new(
          variant: variant,
          price: 10,
          quantity: 0,
          promo_total: -2,
          additional_tax_total: 4
        )
      end

      it "excludes the line item" do
        expect(subject).to eq(
          to_country: "US",
          to_zip: "90210",
          to_city: "Los Angeles",
          to_state: "CA",
          to_street: "475 N Beverly Dr",

          shipping: 3.01,

          line_items: []
        )
      end
    end
  end

  describe "#address_params" do
    subject { described_class.address_params(ship_address) }

    it "returns params for fetching the tax info for that address" do
      expect(subject).to eq([
        "90210",
        {
          city: "Los Angeles",
          country: "US",
          state: "CA",
          street: "475 N Beverly Dr"
        }
      ])
    end
  end

  describe "#transaction_params" do
    subject { described_class.transaction_params(order) }

    it "returns params for creating/updating an order transaction" do
      expect(subject).to eq({
       amount: BigDecimal("113.58"),
       sales_tax: BigDecimal("9.87"),
       shipping: BigDecimal("3.01"),
       to_city: "Los Angeles",
       to_country: "US",
       to_state: "CA",
       to_street: "475 N Beverly Dr",
       to_zip: "90210",
       transaction_date: "2018-03-06T12:10:33Z",
       transaction_id: "R111222333",
       line_items: [{
         id: line_item.id,
         quantity: 3,
         product_identifier: "G00D-PR0DUCT",
         product_tax_code: "A_GEN_TAX",
         unit_price: 10,
         discount: 2,
         sales_tax: 4
       }]
      })
    end

    context "when the line item has 0 quantity" do
      let(:line_item) do
        Spree::LineItem.new(
          variant: variant,
          price: 10,
          quantity: 0,
          promo_total: -2,
          additional_tax_total: 4
        )
      end

      it "excludes the line item" do
        expect(subject).to eq({
         amount: BigDecimal("113.58"),
         sales_tax: BigDecimal("9.87"),
         shipping: BigDecimal("3.01"),
         to_city: "Los Angeles",
         to_country: "US",
         to_state: "CA",
         to_street: "475 N Beverly Dr",
         to_zip: "90210",
         transaction_date: "2018-03-06T12:10:33Z",
         transaction_id: "R111222333",
         line_items: []
        })
      end
    end
  end

  describe "#refund_params" do
    subject { described_class.refund_params(reimbursement) }

    it "returns params for creating/updating a refund" do
      expect(subject).to eq({
        amount: BigDecimal("300.00"),
        sales_tax: BigDecimal("33.33"),
        shipping: 0,
        to_city: "Los Angeles",
        to_country: "US",
        to_state: "CA",
        to_street: "475 N Beverly Dr",
        to_zip: "90210",
        transaction_date: "2018-03-06T12:10:33Z",
        transaction_id: "RI123123123",
        transaction_reference_id: "R111222333",
      })
    end
  end
end
