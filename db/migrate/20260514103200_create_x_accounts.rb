# frozen_string_literal: true

class CreateXAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :x_accounts do |t|
      t.integer :user_id, null: false
      t.string :x_user_id, null: false
      t.string :username, null: false
      t.string :display_name, null: false, default: ''
      t.string :avatar_url
      t.boolean :selected, null: false, default: false
      t.boolean :deleted, null: false, default: false
      t.boolean :protected, null: false, default: false
      t.boolean :protected_acknowledged, null: false, default: false
      t.integer :display_count, null: false, default: 5
      t.timestamps
    end

    add_index :x_accounts, %i[user_id x_user_id], unique: true
    add_index :x_accounts, :user_id
  end
end
