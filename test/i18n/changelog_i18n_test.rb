require 'test_helper'

class ChangelogI18nTest < ActiveSupport::TestCase
  LOCALES = %i[ja en].freeze
  TAG_KEYS = %w[ux fix performance new].freeze
  ENTRY_FIELDS = %i[date headline tag description].freeze

  LOCALES.each do |locale|
    test "landing.changelog.heading resolves in #{locale}" do
      value = I18n.t('landing.changelog.heading', locale: locale)
      assert value.present?,
        "landing.changelog.heading is blank or missing for locale :#{locale}"
    end

    TAG_KEYS.each do |tag|
      test "landing.changelog.tags.#{tag} resolves in #{locale}" do
        value = I18n.t("landing.changelog.tags.#{tag}", locale: locale)
        assert value.present?,
          "landing.changelog.tags.#{tag} is blank or missing for locale :#{locale}"
      end
    end

    test "landing.changelog.entries is a non-empty array in #{locale}" do
      entries = I18n.t('landing.changelog.entries', locale: locale)
      assert entries.is_a?(Array), "Expected Array for landing.changelog.entries in :#{locale}, got #{entries.class}"
      assert entries.any?, "landing.changelog.entries is empty for locale :#{locale}"
    end

    test "each changelog entry has all required fields in #{locale}" do
      entries = I18n.t('landing.changelog.entries', locale: locale)
      entries.each_with_index do |entry, i|
        ENTRY_FIELDS.each do |field|
          assert entry[field].present?,
            "Entry #{i} missing :#{field} in locale :#{locale} — entry: #{entry.inspect}"
        end
      end
    end
  end
end
