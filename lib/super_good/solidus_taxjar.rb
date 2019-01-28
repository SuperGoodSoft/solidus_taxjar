require 'solidus_core'
require 'solidus_support'
require 'taxjar'

require "super_good/solidus_taxjar/version"
require "super_good/solidus_taxjar/api"
require "super_good/solidus_taxjar/tax_calculator"
require "super_good/solidus_taxjar/discount_calculator"

module SuperGood
  module SolidusTaxJar
    class << self
      attr_accessor :discount_calculator
      attr_accessor :test_mode
    end

    self.discount_calculator = ::SuperGood::SolidusTaxJar::DiscountCalculator
    self.test_mode = false
  end
end
