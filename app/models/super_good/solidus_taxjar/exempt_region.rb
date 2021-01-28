module SuperGood
  module SolidusTaxjar
    class ExemptRegion < ::Spree::Base
      self.table_name = "super_good_solidus_taxjar_exempt_regions"

      belongs_to :state, class_name: 'Spree::State'
      belongs_to :taxjar_customer, foreign_key: :taxjar_customer_id, class_name: 'SuperGood::SolidusTaxjar::Customer',
                 inverse_of: :taxjar_exempt_regions
      has_one_attached :tax_exemption_document

      validates :state, :taxjar_customer, presence: true
    end
  end
end