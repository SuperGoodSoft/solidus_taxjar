FactoryBot.modify do
  # Solidus's default address factories provide an invalid state and zipcode
  # combination.
  factory :address do
    zipcode { "11430" }

    transient do
      state_code { "NY" }
    end
  end
end
