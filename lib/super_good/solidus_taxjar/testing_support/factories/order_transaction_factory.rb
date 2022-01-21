FactoryBot.define do
  factory :taxjar_order_transaction, class: "SuperGood::SolidusTaxjar::OrderTransaction" do
    order
    transaction_date { Date.current }

    transient do
      last_transaction_id {
        SuperGood::SolidusTaxjar::OrderTransaction
          .latest_for(order)
          &.transaction_id
      }
    end

    transaction_id {
      SuperGood::SolidusTaxjar::TransactionIdGenerator
        .next_transaction_id(
          order: order,
          current_transaction_id: last_transaction_id
        )
    }
  end
end
