ENV['RAILS_ENV'] ||= 'test'

require "bundler/setup"

begin
  require File.expand_path('../dummy/config/environment', __FILE__)
rescue LoadError
  puts 'Could not load dummy application. Please ensure you have run `bundle exec rake test_app`'
  exit
end

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
