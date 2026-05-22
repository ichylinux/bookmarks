# frozen_string_literal: true

require 'test_helper'

class AdminUsersI18nTest < ActiveSupport::TestCase
  EXPECTED_KEYS = %w[
    admin.users.index.title
    admin.users.index.col_id
    admin.users.index.col_email
    admin.users.index.col_x_user_name
    admin.users.index.col_admin_flag
    admin.users.index.col_last_sign_in_at
    admin.users.index.col_created_at
    admin.users.index.col_updated_at
    admin.users.index.col_actions
    admin.users.index.purge_button
    admin.users.index.pagination_label
    admin.users.index.pagination_prev
    admin.users.index.pagination_next
    admin.users.index.pagination_status
    admin.users.confirm_purge.title
    admin.users.confirm_purge.body
    admin.users.confirm_purge.submit
    admin.users.confirm_purge.cancel
    admin.users.purge.success
    admin.users.purge.not_purgeable
    nav.users
  ].freeze

  def test_admin_users_keys_present_in_ja
    ja = YAML.load_file(Rails.root.join('config/locales/ja.yml'))['ja']
    EXPECTED_KEYS.each do |dotted|
      val = dotted.split('.').reduce(ja) { |h, k| h.is_a?(Hash) ? h[k] : nil }
      assert val.present?, "ja.yml missing key: #{dotted}"
    end
  end

  def test_admin_users_keys_present_in_en
    en = YAML.load_file(Rails.root.join('config/locales/en.yml'))['en']
    EXPECTED_KEYS.each do |dotted|
      val = dotted.split('.').reduce(en) { |h, k| h.is_a?(Hash) ? h[k] : nil }
      assert val.present?, "en.yml missing key: #{dotted}"
    end
  end
end
