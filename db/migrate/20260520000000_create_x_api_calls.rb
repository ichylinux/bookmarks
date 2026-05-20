class CreateXApiCalls < ActiveRecord::Migration[8.1]
  def change
    create_table :x_api_calls do |t|
      t.datetime :called_at,            null: false
      t.string   :endpoint,             null: false
      t.string   :error_code,           limit: 32
      t.integer  :rate_limit_remaining
      t.boolean  :success,              null: false
      t.integer  :user_id,              null: false
    end

    add_index :x_api_calls, %i[user_id called_at]
  end
end
