# frozen_string_literal: true

class CreateCleanUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :clean_users do |t|
      t.string :name

      t.timestamps
    end
  end
end
