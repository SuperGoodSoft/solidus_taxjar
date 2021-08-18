require "spec_helper"

RSpec.describe SuperGood::SolidusTaxjar::ApiParams do
  let(:order) do
    Spree::Order.create!(
      additional_tax_total: BigDecimal("9.87"),
      item_total: BigDecimal("28.00"),
      line_items: [line_item],
      number: "R111222333",
      ship_address: ship_address,
      store: store,
      total: order_total,
      shipments: [shipment],
      user_id: 12345
    ).tap do |order|
      order.update! completed_at: DateTime.new(2018, 3, 6, 12, 10, 33)
    end
  end
  let(:order_total) { BigDecimal("123.45") }

  let(:store) do
    Spree::Store.create!(
      cart_tax_country_iso: "US",
      code: "store",
      mail_from_address: "contact@example.com",
      name: "Default Store",
      url: "https://store.example.com"
    )
  end

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

  let(:state_california) do
    Spree::State.create!(
      abbr: "CA",
      country: country_us,
      name: "California"
    )
  end

  let(:line_item) do
    Spree::LineItem.new(
      additional_tax_total: 4,
      price: 10,
      promo_total: -2,
      quantity: 3,
      variant: variant
    )
  end

  let(:variant) do
    Spree::Variant.create!(
      price: 10,
      product: product,
      sku: "G00D-PR0DUCT"
    )
  end

  let(:product) do
    Spree::Product.create!(
      master: master_variant,
      name: "Product Name",
      shipping_category: shipping_category,
      tax_category: tax_category,
      variants: [master_variant]
    )
  end

  let(:shipping_category) do
    Spree::ShippingCategory.create!(name: "Default Category")
  end

  let(:tax_category) do
    Spree::TaxCategory.create!(
      is_default: true,
      name: "Default",
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
      number: "RI123123123",
      order: order,
      return_items: [
        Spree::ReturnItem.new(additional_tax_total: 0.33),
        Spree::ReturnItem.new(additional_tax_total: 33.0)
      ],
      total: 333.33
    )
  end

  let(:shipment) { Spree::Shipment.create!(cost: BigDecimal("3.01")) }

  describe ".order_params" do
    subject { described_class.order_params(order) }

    it "returns params for fetching the tax for the order" do
      expect(subject).to eq(
        customer_id: "12345",
        line_items: [{
          discount: 2.00,
          id: order.line_items.first.id,
          product_tax_code: "A_GEN_TAX",
          quantity: 3,
          unit_price: 10.00
        }],
        shipping: 3.01,
        to_city: "Los Angeles",
        to_country: "US",
        to_state: "CA",
        to_street: "475 N Beverly Dr",
        to_zip: "90210"
      )
    end

    context "when custom params are used" do
      around do |example|
        default = SuperGood::SolidusTaxjar.custom_order_params
        SuperGood::SolidusTaxjar.custom_order_params = ->(order) {
          {
            nexus_addresses: [
              {
                id: "Main Location",
                country: "AU",
                zip: "NSW 2000",
                city: "Sydney",
                street: "483 George St"
              }
            ]
          }
        }
        example.run
        SuperGood::SolidusTaxjar.custom_order_params = default
      end

      it "returns params for fetching the tax for the order" do
        expect(subject).to eq(
          customer_id: "12345",
          line_items: [{
            discount: 2.00,
            id: order.line_items.first.id,
            product_tax_code: "A_GEN_TAX",
            quantity: 3,
            unit_price: 10.00
          }],
          nexus_addresses: [{
            id: "Main Location",
            country: "AU",
            zip: "NSW 2000",
            city: "Sydney",
            street: "483 George St"
          }],
          shipping: 3.01,
          to_city: "Los Angeles",
          to_country: "US",
          to_state: "CA",
          to_street: "475 N Beverly Dr",
          to_zip: "90210"
        )
      end
    end

    context "when the line item has zero quantity" do
      let(:line_item) do
        Spree::LineItem.new(
          additional_tax_total: 4,
          price: 10,
          promo_total: -2,
          quantity: 0,
          variant: variant
        )
      end

      it "excludes the line item" do
        expect(subject).to eq(
          customer_id: "12345",
          line_items: [],
          shipping: 3.01,
          to_city: "Los Angeles",
          to_country: "US",
          to_state: "CA",
          to_street: "475 N Beverly Dr",
          to_zip: "90210"
        )
      end
    end
  end

  describe ".address_params" do
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

  describe ".tax_rate_address_params" do
    subject { described_class.tax_rate_address_params(ship_address) }

    it "returns params for fetching the tax rate for that address" do
      expect(subject).to eq(
        {
          amount: 100,
          shipping: 0,
          to_city: "Los Angeles",
          to_country: "US",
          to_state: "CA",
          to_street: "475 N Beverly Dr",
          to_zip: "90210"
        }
      )
    end
  end

  describe ".transaction_params" do
    subject { described_class.transaction_params(order) }

    it "returns params for creating/updating an order transaction" do
      expect(subject).to eq({
        amount: BigDecimal("113.58"),
        customer_id: "12345",
        line_items: [{
          discount: 2,
          id: line_item.id,
          product_identifier: "G00D-PR0DUCT",
          product_tax_code: "A_GEN_TAX",
          quantity: 3,
          sales_tax: 4,
          unit_price: 10
        }],
        sales_tax: BigDecimal("9.87"),
        shipping: BigDecimal("3.01"),
        to_city: "Los Angeles",
        to_country: "US",
        to_state: "CA",
        to_street: "475 N Beverly Dr",
        to_zip: "90210",
        transaction_date: "2018-03-06T12:10:33Z",
        transaction_id: "R111222333"
      })
    end

    context "when the order is adjusted to 0" do
      let(:order_total) { BigDecimal("0") }

      it "sends the order total as zero" do
        expect(subject[:amount]).to be_zero
      end

      it "sends the sales tax total as zero" do
        expect(subject[:sales_tax]).to be_zero
      end

      it "sends the sales tax on the line items as zero" do
        expect(subject[:line_items]).to contain_exactly({
          discount: 2,
          id: line_item.id,
          product_identifier: "G00D-PR0DUCT",
          product_tax_code: "A_GEN_TAX",
          quantity: 3,
          sales_tax: 0,
          unit_price: 10
        })
      end
    end

    context "when the line item has 0 quantity" do
      let(:line_item) do
        Spree::LineItem.new(
          additional_tax_total: 4,
          price: 10,
          promo_total: -2,
          quantity: 0,
          variant: variant
        )
      end

      it "excludes the line item" do
        expect(subject).to eq({
          amount: BigDecimal("113.58"),
          customer_id: "12345",
          line_items: [],
          sales_tax: BigDecimal("9.87"),
          shipping: BigDecimal("3.01"),
          to_city: "Los Angeles",
          to_country: "US",
          to_state: "CA",
          to_street: "475 N Beverly Dr",
          to_zip: "90210",
          transaction_date: "2018-03-06T12:10:33Z",
          transaction_id: "R111222333"
        })
      end
    end

    context "with an optional transaction_id specified" do
      subject {
        described_class.transaction_params(order, custom_transaction_id)
      }

      let(:custom_transaction_id) { "R0123456789" }

      it "uses the specified transaction_id" do
        expect(subject).to include(transaction_id: "R0123456789")
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
        transaction_reference_id: "R111222333"
      })
    end
  end

  describe "#validate_address_params" do
    subject { described_class.validate_address_params(ship_address) }

    it "returns params for validating an address" do
      expect(subject).to eq({
        country: "US",
        state: "CA",
        zip: "90210",
        city: "Los Angeles",
        street: "475 N Beverly Dr"
      })
    end

    context "with an address without a state" do
      let(:ship_address) do
        Spree::Address.create!(
          address1: "72 High St",
          city: "Birmingham",
          country: country_uk,
          first_name: "Chuck",
          last_name: "Schuldiner",
          phone: "1-250-555-4444",
          state_name: "West Midlands",
          zipcode: "B4 7TA"
        )
      end

      let(:country_uk) do
        Spree::Country.create!(
          iso3: "GBR",
          iso: "GB",
          iso_name: "UNITED KINGDOM",
          name: "United Kingdom",
          numcode: 826,
          states_required: false
        )
      end

      it "uses the state_name to build address params" do
        expect(subject).to eq({
          country: "GB",
          state: "West Midlands",
          zip: "B4 7TA",
          city: "Birmingham",
          street: "72 High St"
        })
      end
    end

    context "an address with address2" do
      let(:ship_address) do
        Spree::Address.create!(
          address1: "1 World Trade CTR",
          address2: "STE 45A",
          city: "New York",
          country: country_us,
          first_name: "Chuck",
          last_name: "Schuldiner",
          phone: "1-250-555-4444",
          state: Spree::State.create!(
            abbr: "NY",
            country: country_us,
            name: "New York"
          ),
          zipcode: "10007"
        )
      end

      it "concatenates address1 and address2 into the street parameter" do
        expect(subject).to eq({
          country: "US",
          state: "NY",
          zip: "10007",
          city: "New York",
          street: "1 World Trade CTR STE 45A"
        })
      end
    end
  end
end
