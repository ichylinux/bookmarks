class PreferencesController < ApplicationController

  def index
    @user = User.find(current_user.id)
    @user.build_preference unless @user.preference.present?
  end

  def create
    @user = User.find(current_user.id)
    attrs = user_params
    if attrs[:preference_attributes].respond_to?(:key?) && attrs[:preference_attributes].key?(:locale)
      attrs[:preference_attributes][:locale] = attrs[:preference_attributes][:locale].presence
    end
    @user.attributes = attrs

    @user.transaction do
      @user.save!
    end

    flash[:notice] = saved_notice
    redirect_to preferences_path
  end

  def update
    @user = User.find(current_user.id)
    attrs = user_params
    if attrs[:preference_attributes].respond_to?(:key?) && attrs[:preference_attributes].key?(:locale)
      attrs[:preference_attributes][:locale] = attrs[:preference_attributes][:locale].presence
    end
    @user.attributes = attrs

    @user.transaction do
      @user.save!
    end

    flash[:notice] = saved_notice
    redirect_to preferences_path
  end

  private

  def user_params
    permitted = [
      :name,
      preference_attributes: [
        :id, :theme, :font_size, :use_todo, :default_priority, :use_note, :use_calendar, :open_links_in_new_tab, :locale
      ]
    ]

    params.require(:user).permit(permitted)
  end

  def saved_notice
    candidate = @user.preference&.locale
    if candidate.present? && Preference::SUPPORTED_LOCALES.include?(candidate.to_s)
      I18n.with_locale(candidate.to_sym) { t('preferences.saved') }
    else
      t('preferences.saved')
    end
  end

end
