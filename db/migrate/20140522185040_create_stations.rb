class CreateStations < ActiveRecord::Migration
  def change
    create_table :stations do |t|
      t.string :name, null: false
      t.string :code, null: false

      t.timestamps
    end

    add_index :stations, :code, unique: true, name: 'UNIQUE'
  end
end
