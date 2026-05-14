# frozen_string_literal: true

class AddXAccountsLastRefreshedAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :x_accounts_last_refreshed_at, :datetime
  end
end
