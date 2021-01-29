module SuperGood
  module SolidusTaxjar
    module Spree
      module UserDecorator
        def self.prepended(base)
          base.has_one :taxjar_customer, class_name: "SuperGood::SolidusTaxjar::Customer", inverse_of: :user
          base.has_many :taxjar_exempt_regions, class_name: "SuperGood::SolidusTaxjar::ExemptRegion", through: :taxjar_customer

          base.accepts_nested_attributes_for :taxjar_customer
        end

        ::Spree.user_class.prepend self
      end
    end
  end
end
