class RemoveUseTwoFactorAuthenticationFromPreferences < ActiveRecord::Migration[7.2]
  def change
    remove_column :preferences, :use_two_factor_authentication, :boolean
  end
end
