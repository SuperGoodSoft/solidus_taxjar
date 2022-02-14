require "solidus_core"
require "solidus_support"
require "taxjar"
require "super_good/solidus_taxjar/overrides/request_override"

require "super_good/solidus_taxjar/version"
require "super_good/solidus_taxjar/transaction_id_generator"
require "super_good/solidus_taxjar/api_params"
require "super_good/solidus_taxjar/api"
require "super_good/solidus_taxjar/calculator_helper"
require "super_good/solidus_taxjar/tax_calculator"
require "super_good/solidus_taxjar/tax_rate_calculator"
require "super_good/solidus_taxjar/discount_calculator"
require "super_good/solidus_taxjar/addresses"
require "super_good/solidus_taxjar/reporting"
require "super_good/solidus_taxjar/backfill_transactions"

module SuperGood
  module SolidusTaxjar
    class << self
      attr_accessor :cache_duration
      attr_accessor :cache_key
      attr_accessor :custom_order_params
      attr_accessor :discount_calculator
      attr_accessor :exception_handler
      attr_accessor :job_queue
      attr_accessor :line_item_tax_label_maker
      attr_accessor :logging_enabled
      attr_accessor :reporting_ui_enabled
      attr_accessor :shipping_calculator
      attr_accessor :shipping_tax_label_maker
      attr_accessor :taxable_address_check
      attr_accessor :taxable_order_check
      attr_accessor :test_mode
      attr_writer :logger

      def configuration
        ::SuperGood::SolidusTaxjar::Configuration.default
      end

      def api
        ::SuperGood::SolidusTaxjar::Api.new
      end

      def table_name_prefix
        "solidus_taxjar_"
      end

      def reporting
        ::SuperGood::SolidusTaxjar::Reporting.new
      end

      def logger
        @logger || Rails.logger
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
      self.logger.error "An error occurred while fetching TaxJar tax rates - #{e}: #{e.message}"
    }
    self.job_queue = :default
    self.line_item_tax_label_maker = ->(taxjar_line_item, spree_line_item) { "Sales Tax" }
    self.logging_enabled = true

    # The reporting setting in the admin UI is disabled for now till the reporting
    # feature is fully implemented.
    self.reporting_ui_enabled = false

    self.shipping_calculator = ->(order) { order.shipments.sum(&:total_before_tax) }
    self.shipping_tax_label_maker = ->(shipment, shipping_tax) { "Sales Tax" }
    self.taxable_address_check = ->(address) { true }
    self.taxable_order_check = ->(order) { true }
    self.test_mode = false
  end
end
