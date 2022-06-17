FactoryBot.define do
  factory :taxjar_refund_transaction, class: "SuperGood::SolidusTaxjar::RefundTransaction" do
    order_transaction { create :taxjar_order_transaction }
    sequence(:transaction_id) { |n| "RefundTransaction-#{n}" }
    transaction_date { Date.current }
  end
end
