# frozen_string_literal: true
#
require 'spec_helper'

RSpec.describe SuperGood::SolidusTaxjar::UpdateOrderJob do
  it "updates the order's transaction in TaxJar" do
    taxjar = stub_taxjar_client
    order = build_stubbed(:order)

    described_class.perform_now(order)

    expect(taxjar).to have_received(:update_transaction_for).with(order)
  end
end
