# frozen_string_literal: true

require 'test_helper'

module Admin
  class XApiUsagesControllerTest < ActionDispatch::IntegrationTest
    def setup
      XApiCall.delete_all
    end

    def test_未ログインはサインインページへリダイレクトされる
      get admin_x_api_usages_path
      assert_redirected_to new_user_session_path
    end

    def test_非管理者は404を返す
      sign_in users(:two)
      get admin_x_api_usages_path
      assert_response :not_found
    end

    def test_管理者は200を返す
      sign_in users(:one)
      get admin_x_api_usages_path
      assert_response :success
      assert_select 'h1', text: I18n.t('admin.x_api_usages.index.title', locale: :ja)
    end

    def test_利用記録があるユーザー行が表示される
      admin = users(:one)
      twitter = users(:twitter_user)
      XAccount.create!(
        user: twitter,
        x_user_id: '551199',
        username: 'report_x_user',
        display_name: 'Report X',
        selected: true
      )
      XApiCall.record!(user_id: twitter.id, endpoint: 'fetch_following', success: true)
      sign_in admin
      get admin_x_api_usages_path
      assert_response :success
      assert_select 'td', text: '@report_x_user'
    ensure
      XAccount.where(user_id: twitter.id, username: 'report_x_user').delete_all
    end

    def test_初回表示は直近7日がデフォルトになる
      sign_in users(:one)
      travel_to Time.zone.local(2026, 5, 21, 12, 0, 0) do
        XApiCall.record!(user_id: users(:two).id, endpoint: 'fetch_following', success: true)
        get admin_x_api_usages_path
        assert_response :success
        assert_select 'input#from[value=?]', 7.days.ago.to_date.iso8601
        assert_select 'input#to[value=?]', Date.current.iso8601
        assert_select 'th a', text: I18n.t('admin.x_api_usages.index.col_called_at', locale: :ja)
      end
    end

    def test_日付範囲はユーザーと日単位で集計される
      admin = users(:one)
      twitter = users(:twitter_user)
      day = Time.zone.local(2026, 5, 20, 12, 0, 0)
      travel_to day do
        2.times { XApiCall.record!(user_id: twitter.id, endpoint: 'fetch_following', success: true) }
      end
      sign_in admin
      get admin_x_api_usages_path,
          params: { from: day.to_date.iso8601, to: day.to_date.iso8601 }
      assert_response :success
      assert_select 'tbody tr', count: 1
      assert_select 'tbody tr td:nth-child(3)', text: '2'
    end

    def test_日付範囲で絞り込める
      admin = users(:one)
      twitter = users(:twitter_user)
      XApiCall.create!(user_id: twitter.id, endpoint: 'fetch_following', success: true,
                       called_at: 10.days.ago)
      XApiCall.record!(user_id: twitter.id, endpoint: 'fetch_following', success: true)
      sign_in admin
      get admin_x_api_usages_path, params: { from: 1.day.ago.to_date.iso8601, to: Date.current.iso8601 }
      assert_response :success
      assert_select 'tbody tr', count: 1
      assert_select 'th a', text: I18n.t('admin.x_api_usages.index.col_called_at', locale: :ja)
      assert_select 'th a', text: I18n.t('admin.x_api_usages.index.col_total_calls', locale: :ja)
    end

    def test_日付未指定の絞り込みは全期間の集計表示になる
      admin = users(:one)
      twitter = users(:twitter_user)
      XApiCall.create!(user_id: twitter.id, endpoint: 'fetch_following', success: true,
                       called_at: 10.days.ago)
      XApiCall.record!(user_id: twitter.id, endpoint: 'fetch_following', success: true)
      sign_in admin
      get admin_x_api_usages_path, params: { from: '', to: '' }
      assert_response :success
      assert_select 'tbody tr', count: 1
      assert_select 'th a', text: I18n.t('admin.x_api_usages.index.col_last_called_at', locale: :ja)
      assert_select 'tbody tr td:nth-child(2)', text: '2'
    end

    def test_総呼び出し回数で昇順ソートできる
      admin = users(:one)
      u2 = users(:two)
      XApiCall.record!(user_id: u2.id, endpoint: 'fetch_following', success: true)
      3.times { XApiCall.record!(user_id: admin.id, endpoint: 'fetch_following', success: true) }
      sign_in admin
      get admin_x_api_usages_path, params: { from: '', to: '', sort: 'total_calls', direction: 'asc' }
      assert_response :success
      cells = css_select('tbody tr td:nth-child(2)').map(&:text)
      assert_equal %w[1 3], cells
    end
  end
end
