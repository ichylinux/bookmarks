class AddManuallyAddedToXAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :x_accounts, :manually_added, :boolean, null: false, default: false
  end
end
