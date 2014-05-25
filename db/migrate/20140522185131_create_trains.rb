class CreateTrains < ActiveRecord::Migration
  def change
    create_table :trains do |t|
      t.integer :number, null: false
      t.string :name, null: false

      t.timestamps
    end

    add_index :trains, :number, unique: true, name: 'UNIQUE'
  end
end
