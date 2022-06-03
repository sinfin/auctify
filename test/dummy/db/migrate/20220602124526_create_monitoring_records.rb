# frozen_string_literal: true

class CreateMonitoringRecords < ActiveRecord::Migration[6.1]
  def change
    create_table :monitoring_records do |t|
      t.text :data

      t.timestamps
    end
  end
end
