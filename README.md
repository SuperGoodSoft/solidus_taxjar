# `SuperGood::SolidusTaxjar` [![Build Status](https://travis-ci.com/SuperGoodSoft/solidus_taxjar.svg?token=rc5QTgHvLLF7cpqkmyfd&branch=master)](https://travis-ci.com/SuperGoodSoft/solidus_taxjar)

`SuperGood::SolidusTaxjar` is a [Solidus](https://github.com/solidusio/solidus)
extension that allows Solidus stores to use [TaxJar](https://www.taxjar.com/)
for tax calculations.

This is not a fork of [spree_taxjar](https://github.com/vinsol-spree-contrib/spree_taxjar),
like [solidus_taxjar](https://github.com/boomerdigital/solidus_taxjar). Instead
of using a custom calculator, `SuperGood::SolidusTaxjar` uses the new
configurable tax system [by @adammathys](https://github.com/solidusio/solidus/pull/1892)
introduced in Solidus v2.4. This maps better to how the TaxJar API itself works.

## Installation

1. Add this line to your application's Gemfile:

    ```ruby
    gem 'super_good-solidus_taxjar'
    ```

    And then execute:

    ```sh
    bundle
    ```

1. Next, configure Solidus to use this gem by running the install generator:

    ```sh
    bundle exec rails generate super_good:solidus_taxjar:install
    ```

1. Also, configure your error handling:

    ```ruby
    # Put this in config/initializers/taxjar.rb

    SuperGood::SolidusTaxjar.exception_handler = ->(e) {
      # Report exceptions in here. For example, if you were using the Sentry's
      # raven-ruby gem to report errors, you might do this:
      Raven.capture_exception(e)
    }
    ```

1. Finally, make sure that the `TAXJAR_API_KEY` environment variable is set to
  your TaxJar API key and make sure that you have a `Spree::TaxRate` with the name
  "Sales Tax". This will be used as the source for the tax adjustments that
  Solidus creates.

## Project Status

This extension is under active development and not yet at a v1.0 release, but
it's currently being used in production by multiple Solidus stores.

Requirements for TaxJar integrations vary as some stores also need reporting,
which isn't provided out of the box by this extension. This is because
individual stores will be using different background job frameworks or runners
(Sidekiq, delayed_job, ActiveJob, etc.) and a reliable integration will rely on
one of these. Because this part of the integration is small, we've chosen to
provide the transaction reporting functionality, but have skipped directly
integrating it.

If you're having trouble integrating this extension with your store and would
like some assistance, please reach out to Jared via e-mail at [jared@super.gd](mailto:jared@super.gd)
or on the official Solidus Slack as `@Jared Norman`.

## Features

The extension provides currently two high level `calculator` classes that wrap
the low-level Ruby taxjar gem API calls:

* tax calculator
* tax rate calculator

The extension requires the `order_recalculated` event which is not supported on
Solidus < 2.11, so this extension provides a [compatibility layer](app/decorators/super_good/solidus_taxjar/spree/order_updater/fire_recalculated_event.rb).

### TaxCalculator

`SuperGood::SolidusTaxjar::TaxCalculator` allows calculating the full tax
breakdown for a given `Spree::Order`. The breakdown includes separate line items
taxes and shipment taxes.

### TaxRateCalculator

`SuperGood::SolidusTaxjar::TaxRateCalculator` allows calculating the tax rate
for a given `Spree::Address`. It relies on the same low-level Ruby TaxJar API
endpoint of the tax calculator in order to provide the most coherent and
reliable results. TaxJar support recommends using this endpoint for live
calculations.

## Development Setup

The environment variables needed for development are listed in `.env.sample`. Copy these to `.env`, replace the appropriate values, and run `source .env` in your terminal.
  * **NOTE: These environment variables need to be set when installing dependencies, running specs, and running the sandbox app**
  * You can get a TaxJar API key by [signing up for a free trial](https://app.taxjar.com/sign_up).

After setting the environment variables, run `bin/setup` to install dependencies. These dependencies should match the rails/solidus versions you specified in your environment variables.


### Running the Tests

The tests are written in rspec, and can be run with `bundle exec rspec`

* If this is the first time you've run the tests, you will notice that a "dummy" rails application is created in `spec/dummy`
* **NOTE: If you change the `RAILS_VERSION` or `SOLIDUS_BRANCH` environment variables, you will need to delete this folder before running the tests again**

### Running a local Solidus app with TaxJar

This extension uses the `solidus_dev_support` gem to provide tooling for developing extensions. One of it's most important features is the sandbox app, which runs a solidus store with this extension hooked in.

https://github.com/solidusio/solidus_dev_support#sandbox-app

By using `bin/rails-sandbox`, you can run any command that `bin/rails` would accept (`bin/rails-sandbox server`, `bin/rails-sandbox console`), except it will run it on a locally generated sandbox store.

* `binding.pry`s set in your local source code will be hit by the sandbox app, as it links itself directly to your development folder.
* If this is the first time you've run the sandbox, you will notice that a `sandbox` folder is created with a solidus store.
* **NOTE: If you change the `RAILS_VERSION` or `SOLIDUS_BRANCH` environment variables, you will need to delete this folder before running the tests again**

### Releasing a new version

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`, and then
run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/SuperGoodSoft/solidus_taxjar](https://github.com/SuperGoodSoft/solidus_taxjar).
This project is intended to be a safe, welcoming space for collaboration, and
contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org)
code of conduct.

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the `SuperGood::SolidusTaxjar` project’s codebases,
issue trackers, chat rooms and mailing lists is expected to follow the
[code of conduct](https://github.com/SuperGoodSoft/solidus_taxjar/blob/master/CODE_OF_CONDUCT.md).
