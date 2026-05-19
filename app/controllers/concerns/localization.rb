module Localization
  extend ActiveSupport::Concern

  included do
    around_action :set_locale
  end

  private

  def set_locale(&block)
    I18n.with_locale(resolved_locale, &block)
  end

  def resolved_locale
    [requested_locale, saved_locale, guest_session_locale, accept_language_match].each do |candidate|
      return candidate.to_sym if candidate && Preference::SUPPORTED_LOCALES.include?(candidate.to_s)
    end
    I18n.default_locale
  end

  def requested_locale
    requested = params[:locale].to_s.presence
    return nil unless requested && Preference::SUPPORTED_LOCALES.include?(requested)

    session[:guest_locale] = requested unless user_signed_in?
    requested
  end

  def saved_locale
    saved_locale_user&.preference&.locale
  end

  def saved_locale_user
    return current_user if user_signed_in?
    return nil if session[:otp_user_id].blank?

    User.find_by(id: session[:otp_user_id])
  end

  def guest_session_locale
    return nil if user_signed_in?

    session[:guest_locale]
  end

  def accept_language_match
    parse_accept_language(request.env['HTTP_ACCEPT_LANGUAGE'])
  end

  def parse_accept_language(header)
    return nil if header.blank?
    header
      .split(',')
      .map { |entry|
        tag, q = entry.strip.split(';q=')
        q_value = q ? q.to_f : 1.0
        [tag.to_s.strip[0, 2], q_value]
      }
      .sort_by { |_, q| -q }
      .find { |tag, _| Preference::SUPPORTED_LOCALES.include?(tag) }
      &.first
  rescue
    nil
  end
end
