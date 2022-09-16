FactoryBot.define do
  factory :transaction_sync_log, class: "SuperGood::SolidusTaxjar::TransactionSyncLog" do
    association :order, strategy: :create

    trait :success do
      status { "success" }

      after :build do |log|
        log.order_transaction = build(:taxjar_order_transaction, order: log.order)
      end
    end
  end
end
