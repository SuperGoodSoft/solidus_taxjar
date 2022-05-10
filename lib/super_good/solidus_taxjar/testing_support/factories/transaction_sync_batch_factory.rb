FactoryBot.define do
  factory :transaction_sync_batch, class: "SuperGood::SolidusTaxjar::TransactionSyncBatch" do
    trait :with_logs do
      after :build do |batch|
        batch.transaction_sync_logs << build(:transaction_sync_log)
      end
    end
  end
end
