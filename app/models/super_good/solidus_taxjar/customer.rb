module SuperGood
  module SolidusTaxjar
    class Customer < ::Spree::Base
      self.table_name = "super_good_solidus_taxjar_customers"

      EXEMPTION_TYPES = %w[wholesale government marketplace other]

      belongs_to :user, class_name: ::Spree::UserClassHandle.new, inverse_of: :taxjar_customer
      belongs_to :address, class_name: 'Spree::Address'
      has_many :taxjar_exempt_regions, foreign_key: :taxjar_customer_id,
               class_name: 'SuperGood::SolidusTaxjar::ExemptRegion', inverse_of: :taxjar_customer
      has_many :states, through: :taxjar_exempt_regions, class_name: 'Spree::State'

      validates :user, :address, presence: true

      accepts_nested_attributes_for :address, :taxjar_exempt_regions
    end
  end
end
