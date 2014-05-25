class CreateTrainSchedules < ActiveRecord::Migration
  def change
    create_table :train_schedules do |t|
      t.integer :train_number
      t.string :station_code, limit: 20
      t.integer :distance_from_origin
      t.string :arrival_time, limit: 10
      t.string :departure_time, limit: 10
      t.boolean :sun, default: false
      t.boolean :mon, default: false
      t.boolean :tue, default: false
      t.boolean :wed, default: false
      t.boolean :thu, default: false
      t.boolean :fri, default: false
      t.boolean :sat, default: false
      t.column :journey_day, 'tinyint(3)', null: false

      t.timestamps
    end

    add_index :train_schedules, [:train_number, :station_code], unique: true, name: 'UNIQUE_INDEX'
    add_index :train_schedules, [:station_code], name: 'INDEX2'
  end
end
