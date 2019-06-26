# Changelog

## master

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
