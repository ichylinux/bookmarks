module ApplicationHelper
  # Returns changelog entries sorted by date (descending), capped at 10.
  # Entries are defined under landing.changelog.entries in each locale YAML.
  # The :date field is a YYYY-MM-DD string; ISO 8601 format sorts correctly
  # with plain string comparison.
  def changelog_entries
    I18n.t('landing.changelog.entries', default: [])
        .sort_by { |entry| entry[:date] }
        .reverse
        .first(10)
  end

  # VIS-02: Returns "link--visited" when the normalized URL is in visited_set,
  # "" otherwise. Delegates normalization to VisitedLink.normalize_url so
  # fragment-stripped URLs match stored values consistently.
  def visited_link_class(visited_set, url)
    normalized = VisitedLink.normalize_url(url)
    visited_set&.include?(normalized) ? "link--visited" : ""
  end

  # Sign-in / sign-up: brand panel already shows logo + name; hide site header on narrow viewports.
  def auth_flow_page?
    !user_signed_in? && devise_controller? && %w[sessions registrations].include?(controller_name)
  end

  LOGGED_IN_BEFORE_STORAGE_KEY = 'bookmarksHasLoggedIn'
  PENDING_VISITED_LINKS_STORAGE_KEY = 'bookmarksPendingVisitedLinks'
  MASTODON_INSTANCE_STORAGE_KEY = 'bookmarksMastodonInstance'
  EXPLICIT_LANDING_PARAM = :landing

  def guest_root_landing_page?
    !user_signed_in? && controller_name == 'welcome' && action_name == 'index'
  end

  def explicit_landing_request?
    params[EXPLICIT_LANDING_PARAM].present?
  end

  def simple_nav_welcome_home_current?
    controller_name == 'welcome' && action_name == 'index' && params[:tab].to_s != 'notes'
  end

  def simple_nav_welcome_notes_open?
    controller_name == 'welcome' && action_name == 'index' && params[:tab].to_s == 'notes'
  end

  def simple_nav_feed_histories_current?
    controller_name == 'feed_article_histories' && action_name == 'index'
  end
end
