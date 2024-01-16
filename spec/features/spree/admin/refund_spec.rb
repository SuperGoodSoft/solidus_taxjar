require "spec_helper"

RSpec.feature "Refunding an order", :js do
  stub_authorization!

  include_context "checkoutable store"

  before do
    create :stock_location, name: "Montez's Warehouse"

    create :return_reason, name: "Defective"
    create :refund_reason,
      code: "refund",
      name: "Return processing",
      mutable: false
    create :reimbursement_type,
      name: "original payment",
      type: "Spree::ReimbursementType::OriginalPayment"
  end

  let(:order) { create(:shipped_order, line_items_attributes: [{}, {}, {quantity: 2}], number: "R525233498") }

  xit "adds tax calculated by TaxJar to the order total", js: true, vcr: {cassette_name: "features/spree/admin/refund", allow_unused_http_interactions: false} do
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

    perform_enqueued_jobs do
      click_on "Reimburse"
    end

    expect(find(".reimbursement-refund-amount")).to have_content("$10.89")

    click_on "RMA"

    click_on "New RMA"
    check "return_authorization[return_items_attributes][1][_destroy]"
    select "Montez's Warehouse", from: "Stock Location"
    select "Original payment", from: "return_authorization[return_items_attributes][1][preferred_reimbursement_type_id]"
    select "Defective", from: "return_authorization[return_items_attributes][1][return_reason_id]"
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

    perform_enqueued_jobs do
      click_on "Reimburse"
    end
  end
end
