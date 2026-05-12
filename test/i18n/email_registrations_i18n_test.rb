require 'test_helper'

class EmailRegistrationsI18nTest < ActiveSupport::TestCase
  %i[ja en].each do |locale|
    test "email_registrations keys resolve in #{locale}" do
      I18n.with_locale(locale) do
        assert I18n.t('email_registrations.saved').present?
        assert I18n.t('email_registrations.new.title').present?
        assert I18n.t('email_registrations.new.email_label').present?
        assert I18n.t('email_registrations.new.submit').present?
        assert I18n.t('email_registrations.new.help').present?
        assert I18n.t('preferences.index.email_registration_section_title').present?
        assert I18n.t('preferences.index.email_registration_link').present?
        assert I18n.t('activerecord.errors.models.user.attributes.email.dummy_email').present?
      end
    end
  end
end
