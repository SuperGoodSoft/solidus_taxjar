# Changelog

## v0.6.2
- Updated `incomplete_address?` method to verify if a `tax_address` is a `Spree::Tax::TaxLocation`. `Spree::Tax::TaxLocation` is considered an incomplete address.

## v0.6.1

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
