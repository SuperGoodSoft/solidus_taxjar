# `SuperGood::SolidusTaxJar` [![Build Status](https://travis-ci.com/SuperGoodSoft/solidus_taxjar.svg?token=rc5QTgHvLLF7cpqkmyfd&branch=master)](https://travis-ci.com/SuperGoodSoft/solidus_taxjar)

`SuperGood::SolidusTaxJar` is a [Solidus](https://github.com/solidusio/solidus) extension that allows Solidus stores to use [TaxJar](https://www.taxjar.com/) for tax calculations.

This is not a fork of [spree_taxjar](https://github.com/vinsol-spree-contrib/spree_taxjar), like [solidus_taxjar](https://github.com/boomerdigital/solidus_taxjar). Instead, `SuperGood::SolidusTaxJar` uses the new configurable tax system [introduced by @adammathys](https://github.com/solidusio/solidus/pull/1892) in Solidus 2.4.

## Installation

1. Add this line to your application's Gemfile:

   ```ruby
   gem 'super_good-solidus_taxjar'
   ```

   And then execute:

       $ bundle

2. Next, configure Solidus to use this gem:

   ```ruby
   # Put this in config/initializers/solidus.rb

   Spree.config do |config|
     config.tax_calculator_class = SuperGood::SolidusTaxJar::TaxCalculator
   end
   ```

3. Also, configure your error handling:

   ```ruby
   # Put this in config/initializers/taxjar.rb

   SuperGood::SolidusTaxJar::TaxCalculator.exception_handler = ->(e) {
     # Report exceptions in here. For example, if you were using the Sentry's
     # raven-ruby gem to report errors, you might do this:
     Raven.capture_exception(exception)
   }
   ```

4. Finally, make sure that the `TAXJAR_API_KEY` environment variable is set to a your TaxJar API key and make sure that you have a `Spree::TaxRate` with the name "Sales Tax". This will be used as the source for the tax adjustments that Solidus creates.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/SuperGoodSoft/solidus_taxjar. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the `SuperGood::SolidusTaxjar` project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/SuperGoodSoft/solidus_taxjar/blob/master/CODE_OF_CONDUCT.md).
