# `SuperGood::SolidusTaxJar` [![Build Status](https://travis-ci.com/SuperGoodSoft/solidus_taxjar.svg?token=rc5QTgHvLLF7cpqkmyfd&branch=master)](https://travis-ci.com/SuperGoodSoft/solidus_taxjar)

`SuperGood::SolidusTaxJar` is a [Solidus](https://github.com/solidusio/solidus) extension that allows Solidus stores to use [TaxJar](https://www.taxjar.com/) for tax calculations.

This is not a fork of [spree_taxjar](https://github.com/vinsol-spree-contrib/spree_taxjar), like [solidus_taxjar](https://github.com/boomerdigital/solidus_taxjar). Instead of using a custom calculator, `SuperGood::SolidusTaxJar` uses the new configurable tax system [by @adammathys](https://github.com/solidusio/solidus/pull/1892) introduced in Solidus v2.4. This maps better to how the TaxJar API itself works.

## Installation

1. Add this line to your application's Gemfile:

   ```ruby
   gem 'super_good_solidus_taxjar'
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

   SuperGood::SolidusTaxJar.exception_handler = ->(e) {
     # Report exceptions in here. For example, if you were using the Sentry's
     # raven-ruby gem to report errors, you might do this:
     Raven.capture_exception(e)
   }
   ```

4. Finally, make sure that the `TAXJAR_API_KEY` environment variable is set to a your TaxJar API key and make sure that you have a `Spree::TaxRate` with the name "Sales Tax". This will be used as the source for the tax adjustments that Solidus creates.

## Project Status

This extension is under active development and not yet at a v1.0 release, but it's currently being used in production by multiple Solidus stores.

Requirements for TaxJar integrations vary as some stores also need reporting, which isn't provided out of the box by this extension. This is because individual stores will be using different background job frameworks or runners (Sidekiq, delayed_job, ActiveJob, etc.) and a reliable integration will rely on one of these. Because this part of the integration is small, we've chosen to provide the transaction reporting functionality, but have skipped directly integrating it.

If you're having trouble integrating this extension with your store and would like some assistance, please reach out to Jared via e-mail at [jared@super.gd](mailto:jared@super.gd) or on the official Solidus as `@jared`.

## Features

The extension provides currently two high level `calculator` classes that wrap the low-level Ruby taxjar gem API calls:

* tax calculator
* tax rate calculator

### TaxCalculator

`SuperGood::SolidusTaxJar::TaxCalculator` allows calculating the full tax breakdown for a given `Spree::Order`. The breakdown includes separate line items taxes and shipment taxes.

### TaxRateCalculator

`SuperGood::SolidusTaxJar::TaxRateCalculator` allows calculating the tax rate for a given `Spree::Address`. It relies on the same low-level Ruby TaxJar API endpoint of the tax calculator in order to provide the most coherent and reliable results. TaxJar support recommends using this endpoint for live calculations.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/SuperGoodSoft/solidus_taxjar. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the `SuperGood::SolidusTaxjar` project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/SuperGoodSoft/solidus_taxjar/blob/master/CODE_OF_CONDUCT.md).
