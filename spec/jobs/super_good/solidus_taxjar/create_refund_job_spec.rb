# frozen_string_literal: true
#
require 'spec_helper'

RSpec.describe SuperGood::SolidusTaxjar::CreateRefundJob do
  it 'creates a refund in TaxJar' do
    taxjar = stub_taxjar_client
    reimbursement = build_stubbed(:reimbursement)

    described_class.perform_now(reimbursement)

    expect(taxjar).to have_received(:create_refund_for).with(reimbursement)
  end
end
