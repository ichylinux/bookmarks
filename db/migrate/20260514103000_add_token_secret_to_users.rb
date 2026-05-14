# frozen_string_literal: true

class AddTokenSecretToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :token_secret, :string
  end
end
