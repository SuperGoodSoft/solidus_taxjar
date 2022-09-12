FactoryBot.define do
  factory :taxjar_configuration, class: "SuperGood::SolidusTaxjar::Configuration" do
    trait :reporting_enabled do
      preferred_reporting_enabled { true }
    end
  end
end
