FactoryBot.define do
  factory :taxjar_order_transaction, class: "SuperGood::SolidusTaxjar::OrderTransaction" do
    order
    transaction_date { Date.current }

    sequence(:transaction_id) { |n|
      if n == 1
        order.number
      else
        "#{order.number}-#{n - 1}"
      end
    }
  end
end
