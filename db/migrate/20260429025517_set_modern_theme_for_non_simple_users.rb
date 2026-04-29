class SetModernThemeForNonSimpleUsers < ActiveRecord::Migration[7.2]
  def up
    Preference.where.not(theme: "simple").update_all(theme: "modern")
  end

  def down
    Preference.where(theme: "modern").update_all(theme: nil)
  end
end
