require 'solidus_core'
require 'solidus_support'
require 'taxjar'

require "super_good/solidus_taxjar/version"
require "super_good/solidus_taxjar/api_params"
require "super_good/solidus_taxjar/api"
require "super_good/solidus_taxjar/tax_calculator"
require "super_good/solidus_taxjar/discount_calculator"

module SuperGood
  module SolidusTaxJar
    class << self
      attr_accessor :discount_calculator
      attr_accessor :test_mode
      attr_accessor :exception_handler
      attr_accessor :taxable_address_check
      attr_accessor :shipping_tax_label_maker
      attr_accessor :line_item_tax_label_maker
    end

    self.discount_calculator = ::SuperGood::SolidusTaxJar::DiscountCalculator
    self.test_mode = false
    self.exception_handler = ->(e) {
      Rails.logger.error "An error occurred while fetching TaxJar tax rates - #{e}: #{e.message}"
    }
    self.taxable_address_check = ->(address) { true }
    self.shipping_tax_label_maker = ->(shipment, shipping_tax) { "Sales Tax" }
    self.line_item_tax_label_maker = ->(taxjar_line_item, spree_line_item) { "Sales Tax" }
  end
end
