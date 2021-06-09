# Changelog

## master

- [#79](https://github.com/SuperGoodSoft/solidus_taxjar/pull/79) Relax Ruby required version to support Ruby 3.0+
- [#51](https://github.com/SuperGoodSoft/solidus_taxjar/pull/51) Add nexus regions method to API
- [#58](https://github.com/SuperGoodSoft/solidus_taxjar/pull/58) Take shipping promotions into account in default calculator
- [#59](https://github.com/SuperGoodSoft/solidus_taxjar/pull/59) Add pry debugging tools
- [#69](https://github.com/SuperGoodSoft/solidus_taxjar/pull/69) Lock ExecJS version
- [#37](https://github.com/SuperGoodSoft/solidus_taxjar/pull/37) Added a basic Taxjar settings admin interface which displays placeholder text.
- [#64](https://github.com/SuperGoodSoft/solidus_taxjar/pull/64) Provide Spree::Address.address2 to TaxJar address validation if it is present.
- [#80](https://github.com/SuperGoodSoft/solidus_taxjar/pull/80) Support order_recalculated event in < 2.11

## v0.18.1

[#52](https://github.com/supergoodsoft/solidus_taxjar/pull/52) fixes a critical bug in the API class that was released in `v0.18.0`. Please upgrade.

- [#47](https://github.com/SuperGoodSoft/solidus_taxjar/pull/47) Fixed bug in `validate_address_params` for addresses without a state
- [#52](https://github.com/supergoodsoft/solidus_taxjar/pull/52) Fixed critical bug in API class

## ~~v0.18.0~~
`v0.18.0` was removed due to a regression in the API class that was fixed in [#52](https://github.com/SuperGoodSoft/solidus_taxjar/pull/52) and `v0.18.1`

- [#21](https://github.com/SuperGoodSoft/solidus_taxjar/pull/21) Migrated project to `solidus_dev_support`
- [#22](https://github.com/SuperGoodSoft/solidus_taxjar/pull/22) Added support for TaxJar address validation API through `SuperGood::SolidusTaxJar::Addresses` class
- [#34](https://github.com/SuperGoodSoft/solidus_taxjar/pull/34) Include API version in request headers
- [#38](https://github.com/SuperGoodSoft/solidus_taxjar/pull/38) Added a rails engine to support future solidus backend UI
- [#43](https://github.com/SuperGoodSoft/solidus_taxjar/pull/43) Support zeitwerk loading

**Breaking Changes**:

- Module name `SolidusTaxJar` renamed to `SolidusTaxjar`
- Class name `API` renamed to `Api`
- Class name `APIParams` renamed to `ApiParams`

### Upgrading from 0.17.X to 0.18.X

If you're currently using version 0.17.X and want to upgrade to 0.18.X, follow these steps:

- Rename any instances of the module `SolidusTaxJar` to `SolidusTaxjar`
- Rename any instances of the class `API` to `Api`
- Rename any instances of the class `APIParams` to `ApiParams`

## v0.17.1

- Fixed bug where shipping calculator was not used for order shipping param. (Thanks @spaghetticode!)

## v0.17.0

- Added `SuperGood::SolidusTaxJar.custom_order_params` to allow for custom overrides to the parameters sent to TaxJar when calculating order taxes. For example, if you needed to send a custom nexus address you could do:
  ```ruby
  SuperGood::SolidusTaxJar.custom_order_params = ->(order) {
    {
      nexus_addresses: [
        {
          id: 'Main Location',
          country: 'AU',
          zip: 'NSW 2000',
          city: 'Sydney',
          street: '483 George St',
        }
      ]
    }
  }
  ```
  The callback receives the `Spree::Order` that the params are for and the return value can override existing values like the order's ID.

## v0.16.0

- Fix `#incomplete_address?` method to be friendly also to completely blank addresses.

- Added `SuperGood::SolidusTaxJar::TaxRateCalculator` for retrieving the tax rate for a given `Spree::Address`. The calculator follows `TaxCalculator` conventions by relying on address validators and custom exception handling.

## v0.15.2

- Add order number to param logging.

## v0.15.1

- Add support for request/response logging.

## v0.15.0

- Made sure cache key is a string, instead of a giant nested hash/array structure that probably won't get interpreted by Rails well. Still not happy with the caching behaviour, but it's configurable.

## v0.14.0

- Added `SuperGood::SolidusTaxJar.taxable_order_check` option which can be set to a proc that receives the order and will prevent actual tax calculation from occurring if it returns false. If your app has introduced a method like `Spree::Order#complimentary?`, you could avoid trying to compute taxes on complimentary orders by doing the following in an initializer:
  ```ruby
  SuperGood::SolidusTaxJar.taxable_order_check = ->(order) { order.complimentary? }
  ```

## v0.13.0

- Report order.user_id as customer_id when calculating taxes and creating transactions. This enables the use of per customer exemptions.

## v0.12.0

- Report no tax collected on order and line items when order total zeroed out.

## v0.11.1

- Avoid sending negative amounts for order totals.

## v0.11.0

- Avoid sending 0 quantity line items. TaxJar doesn't like them.

## v0.10.0

- Make shipping amounts configurable to make it easier to support order-level adjustments.

## v0.9.1

- Fixed unreliable default cache key implementation.

## v0.9.0

- Made response cache key and cache duration configurable.

## v0.8.0

- Increased response caching time to 3 hours.

## v0.7.0

- Switched to sending the full list of line items when creating/updating transactions in TaxJar.

## v0.6.2

- Fixed issued where orders without tax address would cause errors because `Spree::Order#tax_address` will return a `Spree::Tax::TaxLocation` when called on an order without a tax address. `Spree::Tax::TaxLocation` isn't enough like a real address and this was causing exceptions.

  To fix this `SuperGood::SolidusTaxJar#incomplete_address?` was updated to treat `Spree::Tax::TaxLocation`s as "incomplete". (Thanks to [@JuanCrg90](https://github.com/JuanCrg90)!)

## v0.6.1

**Warning**: v0.6.1 has a critical bug and should not be used.

- Stopped using the deprecated method `Spree::Address#empty?` in favour of simply checking that we have all of the fields on the address required for doing a TaxJar lookup.

## v0.6.0

- Added `SuperGood::SolidusTaxJar.shipping_tax_label_maker` for customizing the labels on the tax adjustments on shipments.
- Added `SuperGood::SolidusTaxJar.line_item_tax_label_maker` for customizing the labels on the line iteme tax adjustments.

## v0.5.0

- Moved exception handler configuration to `SuperGood::SolidusTaxJar.exception_handler` from `SuperGood::SolidusTaxJar::TaxCalculator.exception_handler`. Now all the configuration options are in the same place.
- Added `SuperGood::SolidusTaxJar.taxable_address_check` option which can be set to a block that receives the address and will prevent actual tax calculator from occurring if it returns false. If your app has introduced a method like `Spree::Address#us?`, you could avoid trying to compute taxes on non-US orders by doing the following in an initializer:
  ```ruby
  SuperGood::SolidusTaxJar.taxable_address_check = ->(address) { address.us? }
  ```
