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
    visited_set.include?(normalized) ? "link--visited" : ""
  end
end
