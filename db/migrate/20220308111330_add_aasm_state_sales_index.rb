# frozen_string_literal: true

class AddAasmStateSalesIndex < ActiveRecord::Migration[6.1]
  def change
    add_index :auctify_sales, :aasm_state
  end
end
