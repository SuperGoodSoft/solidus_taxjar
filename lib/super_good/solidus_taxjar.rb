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
      attr_accessor :exception_handler
      attr_accessor :line_item_tax_label_maker
      attr_accessor :shipping_tax_label_maker
      attr_accessor :taxable_address_check
      attr_accessor :test_mode
    end

    self.discount_calculator = ::SuperGood::SolidusTaxJar::DiscountCalculator
    self.exception_handler = ->(e) {
      Rails.logger.error "An error occurred while fetching TaxJar tax rates - #{e}: #{e.message}"
    }
    self.line_item_tax_label_maker = ->(taxjar_line_item, spree_line_item) { "Sales Tax" }
    self.shipping_tax_label_maker = ->(shipment, shipping_tax) { "Sales Tax" }
    self.taxable_address_check = ->(address) { true }
    self.test_mode = false
  end
end
