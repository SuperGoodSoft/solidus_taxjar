# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SuperGood::SolidusTaxjar::CreateOrderJob do
  it 'creates a transaction in TaxJar' do
    taxjar = stub_taxjar_client
    order = build_stubbed(:order)

    described_class.perform_now(order)

    expect(taxjar).to have_received(:create_transaction_for).with(order)
  end
end
