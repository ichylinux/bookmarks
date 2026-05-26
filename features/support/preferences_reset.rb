# frozen_string_literal: true

module PreferencesReset
  PREF = 'user[preference_attributes]'.freeze
  SAVED_FLASH = /設定を保存しました。|Preferences saved\./

  def reset_preferences_via_browser!
    attempts = 0
    begin
      attempts += 1
      fill_and_save_default_preferences!
    rescue Selenium::WebDriver::Error::UnknownError
      raise if attempts >= 2

      retry
    end
  end

  def select_option_value(field_name, value)
    find(:xpath, "//select[@name=#{field_name.inspect}]")
      .find(:xpath, ".//option[@value=#{value.inspect}]")
      .select_option
  end

  private

  def fill_and_save_default_preferences!
    visit '/preferences'
    assert has_selector?('form.preferences-form')

    select_option_value "#{PREF}[locale]", 'ja'
    select_option_value "#{PREF}[theme]", 'modern'
    select_option_value "#{PREF}[portal_column_count]", '3'
    select_option_value "#{PREF}[default_priority]", Todo::PRIORITY_NORMAL.to_s
    check "#{PREF}[use_bookmark]" unless find_field("#{PREF}[use_bookmark]", visible: :all).checked?
    uncheck_if_checked "#{PREF}[use_note]"
    uncheck_if_checked "#{PREF}[use_todo]"
    check "#{PREF}[use_calendar]" unless find_field("#{PREF}[use_calendar]", visible: :all).checked?
    uncheck_if_checked "#{PREF}[open_links_in_new_tab]"

    find('form.preferences-form input[type="submit"]', match: :first).click
    assert has_text?(SAVED_FLASH)
  end

  def uncheck_if_checked(field_name)
    uncheck(field_name, visible: :all) if find_field(field_name, visible: :all).checked?
  end
end

World(PreferencesReset)
