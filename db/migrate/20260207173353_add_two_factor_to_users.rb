class AddTwoFactorToUsers < ActiveRecord::Migration[7.2]
  def up
    add_column :users, :otp_secret, :string
    add_column :users, :consumed_timestep, :integer
    add_column :users, :otp_required_for_login, :boolean, default: false, null: false

    User.reset_column_information
    User.find_each do |user|
      user.update_column(:otp_secret, User.generate_otp_secret) if user.otp_secret.blank?
    end

    change_column_null :users, :otp_secret, false
  end

  def down
    remove_column :users, :otp_secret
    remove_column :users, :consumed_timestep
    remove_column :users, :otp_required_for_login
  end
end
