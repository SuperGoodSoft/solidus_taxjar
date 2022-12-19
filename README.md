# `SuperGood::SolidusTaxjar`

[![CircleCI build status](https://circleci.com/gh/SuperGoodSoft/solidus_taxjar/tree/master.svg?style=shield)](https://circleci.com/gh/SuperGoodSoft/solidus_taxjar/tree/master)

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

1. Also, configure your own [exception handler](#exception-handling).

1. Finally, make sure that the `TAXJAR_API_KEY` environment variable is set to
  your TaxJar API key.

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

This extension provides two high level `calculator` classes that wrap the
low-level Ruby `taxjar` gem API calls:

* tax calculator
* tax rate calculator

The extension requires the `order_recalculated` event which is not supported on
Solidus < 2.11, so this extension provides a [compatibility layer](app/overrides/super_good/solidus_taxjar/spree/order_updater/fire_recalculated_event.rb).

This extension also supports:

* syncing orders to TaxJar's reporting dashboard
* syncing nexus regions as configured in the connected TaxJar account
* connecting your Solidus store's tax categories to TaxJar's tax categories (U.S. tax codes)

### TaxCalculator

`SuperGood::SolidusTaxjar::TaxCalculator` allows calculating the full tax
breakdown for a given `Spree::Order`. The breakdown includes separate line items
taxes and shipment taxes.

This tax calculator will create a `Spree::TaxRate` that is required for tax
adjustments. All other `Spree::TaxRate`s will be ignored in calculations. See
[this wiki
page](https://github.com/SuperGoodSoft/solidus_taxjar/wiki/How-Solidus-TaxJar-calculates-tax)
for more details.

### TaxRateCalculator

`SuperGood::SolidusTaxjar::TaxRateCalculator` allows calculating the tax rate
for a given `Spree::Address`. It relies on the same low-level Ruby TaxJar API
endpoint of the tax calculator in order to provide the most coherent and
reliable results. TaxJar support recommends using this endpoint for live
calculations.

### Order-level Adjustments are Unsupported

Although Solidus supports order-level adjustments, **TaxJar does not support
order-level adjustments**. Currently, this extension does not make any
assumptions about how order-level adjustments should be reported to TaxJar.
After enabling the extension, any attempts to create an order-level adjustment
will result in an error being raised by default.

**If you need to support order-level adjustments, you'll need to configure the
`discount_calculator` setting to handle them.** See
[Configuration](#configuration) for more more information about configuring the
extension.

## Configuration

Developers can configure the extension in a Rails initializer file. All of the
configuration settings, and their default values, are defined in
[`lib/super_good/solidus_taxjar.rb`](lib/super_good/solidus_taxjar.rb). The
settings are described in the [Settings](#settings) section below.

As an example, your application's initializer might look like this:

```ruby
# config/initializers/taxjar.rb

SuperGood::SolidusTaxjar.tap do |config|
  config.cache_duration = 2.hours
  config.line_item_tax_label_maker = ->(taxjar_line_item, spree_line_item) {
    "My Tax Label"
  }
  config.test_mode = true
end
```

### Settings

Developers can configure the following settings in an initializer:

- `cache_duration`: The length of time that cacheable responses from
  the TaxJar API are cached. Cacheable responses include the list of active
  nexus regions, as well as tax and tax rate calculations.

  Default value: `3.hours`

- `cache_key`:  function that returns a distinct cache key for
  a cacheable response from the TaxJar API. A safe default function is provided.

  Default value: (See the source code.)

- `custom_order_params`: A function that returns any parameterized custom
	order information you need to send to TaxJar in every API request that
	includes a customer's order. By default no custom order parameters are
	sent.

	Note that all the essential `Spree::Order`, `Spree::LineItem`, and
	`Spree::Address` attributes are already sent by default.

	Default value: `{}`

- `discount_calculator`: A discount calculator class. A safe default
  calculator is provided: it handles promotions that rely on line item and
  shipment adjustments. Since TaxJar requires dicounts to be specified per line
  item, you need to provide a custom version of this calculator in order to
  support any of your promotions that create order-level adjustments.

  Default value: `::SuperGood::SolidusTaxjar::DiscountCalculator`

- `exception_handler`: A function that returns your own exception
  handler. See [Exception handling](#exception-handling).

  Default value: (See the source code.)

- `job_queue`: A string or symbol that matches the name of a job queue in your
  application's job queuer. (The extension uses ActiveJob to delegate new jobs.)

	Default value: `:default`

- `line_item_tax_label_maker`: A string to label line item taxes in TaxJar.

  Default value: "Sales Tax"

- `logging_enabled`: Boolean. Whether logging is enabled.

  Default value: `true`

- `shipping_calculator`: A function that calculates the total cost of the
  shipments for an order. A default default is provided
  inline, but your store may require additional logic
  for accurate calculations.

  Default value: (See the source code.)

- `shipping_tax_label_maker`: A string to label shipment taxes in TaxJar.

  Default value: "Sales Tax"

- `taxable_address_check`: A function that returns a boolean after checking
  whether an address should be considered taxable. By default this function
  returns `true`.

  Default value: `true`

- `taxable_order_check`: A function that returns a boolean after checking
  whether an order should be considered taxable.  By default this function
  always returns `true`.

  Default value: `true`

- `test_mode`: Boolean. Whether the extension is in test mode.
  If true, no tax or tax rate calculations will be requested via the TaxJar API.

  Default value: `false`

### Exception handling

You can configure your own exception handler in an initializer. using the
`exception_handler` configuration point:

```ruby
# Put this in config/initializers/taxjar.rb

SuperGood::SolidusTaxjar.exception_handler = ->(e) {
  # Report exceptions in here. For example, if you were using the Sentry's
  # raven-ruby gem to report errors, you might do this:
  Raven.capture_exception(e)
}
```

For more information about configuring the extension, see
[Configuration](#configuration).

### Logging

By default, all requests to TaxJar are logged to the Rails logger. URIs, HTTP
method, and response codes will be logged at the `info` level, any further
details (such as response body) are logged at the `debug` level.

If you are interested in logs for full request responses, be sure to set your
logger to the `debug` level:

```ruby
Rails.logger.level = 0 # debug
```

Or, if you want an alternate logger implementation, you can provide your own:

```ruby
SuperGood::SolidusTaxjar.tap do |config|
  logger = Logger.new(STDOUT)
  logger.log_level = :warn
  config.logger = logger
end
```

More details on the Rails Logger are available [here](https://guides.rubyonrails.org/debugging_rails_applications.html#the-logger).

Logging can also be disabled all together:

```ruby
SuperGood::SolidusTaxjar.tap do |config|
  config.logging_enabled = false
end
```

## Development

Run `bin/setup` to install dependencies. Then, run `bundle exec rake` to run the
tests. You can also run `bin/console` for an interactive prompt that will allow
you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

### Changing the Rails/Solidus Versions

The Rails and the Solidus version can be changed by setting the `RAILS_VERSION`
and `SOLIDUS_BRANCH` environment variables, respectively. See the
[Gemfile](./Gemfile) for examples.

### Changing the Database Vendor

The database vendor can also be changed from the default (`sqlite3`) by setting
the `DB` environment variable.

## Releasing a New Version

1. Update the `master` header in changelog to the version that you're releasing.
2. Commit your changes and open a PR for the release
3. Once the PR has been merged into master, run `gem bump -v [<major>|<minor>|<patch>] -p -t -r` to create a tag and release the gem to ✨ RubyGems ✨
4. Push your local master branch with `--tags` to the repository to add the tag to github.
5. Create a new release on github with the tag
    * [ ] Ensure the changelog since the previous release is included
    * [ ] Ensure you have noted version migration instructions if applicable
    * [ ] Ensure breaking/significant changes are clearly highlighted
    * [ ] Ensure changes that are **not production ready** are clearly highlighted

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
