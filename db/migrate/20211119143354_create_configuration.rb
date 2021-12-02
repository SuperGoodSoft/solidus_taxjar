class CreateConfiguration < ActiveRecord::Migration[5.0]
  def change
    create_table :solidus_taxjar_configuration do |t|
      t.text :preferences
      t.timestamps
    end
  end
end
