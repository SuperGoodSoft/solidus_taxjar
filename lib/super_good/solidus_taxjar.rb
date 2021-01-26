require "solidus_core"
require "solidus_support"
require "taxjar"

require "super_good/solidus_taxjar/version"
require "super_good/solidus_taxjar/api_params"
require "super_good/solidus_taxjar/api"
require "super_good/solidus_taxjar/calculator_helper"
require "super_good/solidus_taxjar/tax_calculator"
require "super_good/solidus_taxjar/tax_rate_calculator"
require "super_good/solidus_taxjar/discount_calculator"
require "super_good/solidus_taxjar/addresses"

module SuperGood
  module SolidusTaxjar
    class << self
      attr_accessor :cache_duration
      attr_accessor :cache_key
      attr_accessor :custom_order_params
      attr_accessor :discount_calculator
      attr_accessor :exception_handler
      attr_accessor :line_item_tax_label_maker
      attr_accessor :logging_enabled
      attr_accessor :shipping_calculator
      attr_accessor :shipping_tax_label_maker
      attr_accessor :taxable_address_check
      attr_accessor :taxable_order_check
      attr_accessor :test_mode

      def api
        ::SuperGood::SolidusTaxjar::Api.new
      end
    end

    self.cache_duration = 3.hours
    self.cache_key = ->(record) {
      record_type = record.class.name.demodulize.underscore
      ApiParams.send("#{record_type}_params", record).to_json
    }
    self.custom_order_params = ->(order) { {} }
    self.discount_calculator = ::SuperGood::SolidusTaxjar::DiscountCalculator
    self.exception_handler = ->(e) {
      Rails.logger.error "An error occurred while fetching TaxJar tax rates - #{e}: #{e.message}"
    }
    self.line_item_tax_label_maker = ->(taxjar_line_item, spree_line_item) { "Sales Tax" }
    self.logging_enabled = false
    self.shipping_calculator = ->(order) { order.shipment_total }
    self.shipping_tax_label_maker = ->(shipment, shipping_tax) { "Sales Tax" }
    self.taxable_address_check = ->(address) { true }
    self.taxable_order_check = ->(order) { true }
    self.test_mode = false
  end
end
