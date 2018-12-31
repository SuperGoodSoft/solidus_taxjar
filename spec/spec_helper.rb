require "bundler/setup"
require "super_good/solidus_taxjar"

# Load the dummy app:
require File.expand_path('../dummy/config/environment.rb',  __FILE__)

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.disable_monkey_patching!
  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.default_formatter = 'doc' if config.files_to_run.one?

  config.order = "random"
  Kernel.srand config.seed
end
