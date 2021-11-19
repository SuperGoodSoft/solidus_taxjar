class CreateSettings < ActiveRecord::Migration[5.0]
  def change
    create_table :solidus_taxjar_settings do |t|
      t.boolean :reporting_enabled, null: false, default: false

      t.timestamps
    end

  end
end
