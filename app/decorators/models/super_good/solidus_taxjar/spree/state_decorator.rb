module SuperGood
  module SolidusTaxjar
    module Spree
      module StateDecorator
        def self.prepended(base)
          base.has_many :taxjar_exempt_regions, class_name: "SuperGood::SolidusTaxjar::ExemptRegion"
          base.has_many :taxjar_customers, through: :taxjar_exempt_regions, class_name: "SuperGood::SolidusTaxjar::Customer"
        end

        ::Spree::State.prepend self
      end
    end
  end
end