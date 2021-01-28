class AddTaxExemptCustomers < ActiveRecord::Migration[5.2]
  def change
    create_table :super_good_solidus_taxjar_customers do |t|
      t.references :user, null: false
      t.references :address, null: false
      t.string :tax_exemption_type, null: false
      t.timestamps
    end

    create_table :super_good_solidus_taxjar_exempt_regions do |t|
      t.references :taxjar_customer, index: {name: 'index_taxjar_exempt_regions_customer_id'}, null: false
      t.references :state, null: false
      t.boolean :approved, null: false, default: false
      t.timestamps
    end

    add_index(:super_good_solidus_taxjar_exempt_regions, [:taxjar_customer_id, :state_id], unique: true,
              name: 'index_taxjar_exempt_regions_customers_states_unique')
  end
end
