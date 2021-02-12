class CreateThings < ActiveRecord::Migration[6.0]
  def change
    create_table :things do |t|
      t.string :name
      t.references :owner, null: false, foreign_key: {to_table: :users}

      t.timestamps
    end
  end
end
