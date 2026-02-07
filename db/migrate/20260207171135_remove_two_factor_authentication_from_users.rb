class RemoveTwoFactorAuthenticationFromUsers < ActiveRecord::Migration[7.2]
  def change
    remove_index :users, :otp_secret_key
    remove_column :users, :otp_secret_key, :string
    remove_column :users, :second_factor_attempts_count, :integer
    remove_column :users, :direct_otp, :string
    remove_column :users, :direct_otp_sent_at, :datetime
    remove_column :users, :totp_timestamp, :datetime
  end
end
