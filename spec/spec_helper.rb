# frozen_string_literal: true

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("dummy/config/environment.rb", __dir__).tap { |file|
  # Create the dummy app if it's still missing.
  system "bin/rake extension:test_app" unless File.exist? file
}

require "solidus_dev_support/rspec/feature_helper"
require 'vcr'

chrome_options = Selenium::WebDriver::Chrome::Options.new.tap do |options|
  options.add_argument("--window-size=#{CAPYBARA_WINDOW_SIZE.join(',')}")
  options.add_argument("--headless")
  options.add_argument("--disable-gpu")
end

version = Capybara::Selenium::Driver.load_selenium
options_key = Capybara::Selenium::Driver::CAPS_VERSION.satisfied_by?(version) ? :capabilities : :options

Capybara.register_driver :solidus_chrome_headless do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome, options_key => chrome_options)
end

factories = Dir["#{::SuperGoodSolidusTaxjar::Engine.root}/lib/super_good/solidus_taxjar/testing_support/factories/**/*_factory.rb"].sort
factories.each { |f| require f }

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.use_transactional_fixtures = false

  config.before do
    Rails.cache.clear
    if RSpec.current_example.metadata[:js] && page.driver.browser.respond_to?(:url_blacklist)
      page.driver.browser.url_blacklist = ['https://fonts.googleapis.com']
    end
  end
end

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/cassettes'
  config.ignore_localhost = true
  config.configure_rspec_metadata!
  config.hook_into :webmock
  driver_urls = Webdrivers::Common.subclasses.map do |driver|
    Addressable::URI.parse(driver.base_url).host
  end
  config.ignore_hosts(
    "chromedriver.storage.googleapis.com",
    *driver_urls
  )
  config.filter_sensitive_data('<BEARER_TOKEN>') { |interaction|
    auths = interaction.request.headers['Authorization'].first
    if (match = auths.match /^Bearer\s+([^,\s]+)/ )
      match.captures.first
    end
  }
end
