require 'test_helper'

class PortalColumnWidthsI18nTest < ActiveSupport::TestCase
  %i[ja en].each do |locale|
    test "#{locale} locale has portal column width preference strings" do
      I18n.with_locale(locale) do
        assert I18n.t('activerecord.attributes.preference.portal_column_widths').present?
        assert I18n.t('preferences.index.portal_column_width_column_label').present?
        assert I18n.t('preferences.index.portal_column_widths_help').present?
      end
    end
  end
end
