FactoryBot.define do
  factory :taxjar_configuration, class: "SuperGood::SolidusTaxjar::Configuration" do
    trait :reporting_enabled do
      preferred_reporting_enabled_at_integer { DateTime.now.to_i }
    end

    trait :reporting_disabled do
      preferred_reporting_enabled_at_integer { nil }
    end
  end
end
