# frozen_string_literal: true

class CreateCleanThings < ActiveRecord::Migration[6.0]
  def change
    create_table :clean_things do |t|
      t.string :name

      t.timestamps
    end
  end
end
