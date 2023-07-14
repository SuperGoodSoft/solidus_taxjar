require 'spec_helper'

RSpec.feature 'Refunding an order', js: true do
  stub_authorization!

  let(:order) { create(:shipped_order, line_items_count: 3) }

  before do
    country = create(:country, states_required: true)
    create(:product, name: "RoR Mug")
    create(:store, default: true)
    create(:state, country: country, state_code: "CA")
    create(:shipping_method)
    create(:stock_location, name: "Montez's Warehouse")
    create(:check_payment_method)
    create(:zone)
    create(:taxjar_configuration, :reporting_enabled)
    create(:return_reason, name: "Defective")
    create(:refund_reason, name: 'Return processing', code: "refund", mutable: false)
    create(:reimbursement_type, name: "original payment", type: "Spree::ReimbursementType::OriginalPayment")

    SuperGood::SolidusTaxjar::ReportTransactionJob.perform_now(order)
  end

  it "adds tax calculated by TaxJar to the order total", js: true, vcr: {cassette_name: "features/spree/admin/refund", allow_unused_http_interactions: false} do
    visit spree.admin_order_return_authorizations_path(order)

    click_on "New RMA"
    check "return_authorization[return_items_attributes][0][_destroy]"
    select "Montez's Warehouse", from: "Stock Location"
    select "Original payment", from: "return_authorization[return_items_attributes][0][preferred_reimbursement_type_id]"
    select "Defective", from: "return_authorization[return_items_attributes][0][return_reason_id]"
    click_on "Create"

    click_on "Customer Return"
    click_on "New Customer Return"
    check "customer_return[return_items_attributes][0][returned]"
    select "Received", from: "customer_return[return_items_attributes][0][reception_status_event]"
    select "Montez's Warehouse", from: "Stock Location"
    click_on "Create"

    click_on "Create reimbursement"
    select "Original payment", from: "reimbursement[return_items_attributes][0][override_reimbursement_type_id]"
    click_on "Update"

    # The current recorded cassette for this line has an incorrect value, but
    # VCR never let's us know because we're only matching on URL and method. We
    # expect to to see amount=$140 in the first reporting request, but we wee
    # amount=$130.
    perform_enqueued_jobs do
      click_on "Reimburse"
    end

    expect(find(".reimbursement-refund-amount")).to have_content("$10.89")
  end
end
