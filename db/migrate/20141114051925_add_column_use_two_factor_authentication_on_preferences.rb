class AddColumnUseTwoFactorAuthenticationOnPreferences < ActiveRecord::Migration
  def change
    add_column :preferences, :use_two_factor_authentication, :boolean, null: false, default: false
  end
end
