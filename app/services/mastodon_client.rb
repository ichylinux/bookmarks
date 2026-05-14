# Public Mastodon REST API client (read-only, no OAuth).
# Uses Faraday with explicit connect + read timeouts.
class MastodonClient
  CONNECT_TIMEOUT = 3
  READ_TIMEOUT = 5
  PREVIEW_LENGTH = 100

  def initialize(instance_host:, connection: nil)
    @instance_host = instance_host.to_s.sub(%r{\Awww\.}i, '')
    @forced_connection = connection
  end

  # Returns { success: true, items: [{ text:, url: }, ...] }
  # or { success: false, error: :timeout | :network | :not_found | :api_error | :parse_error }
  def fetch_recent_status_previews(username:, limit:)
    conn = build_connection
    acct = "#{username}@#{@instance_host}"
    lookup = conn.get('/api/v1/accounts/lookup', { acct: acct })
    unless lookup.status == 200
      return { success: false, error: lookup.status == 404 ? :not_found : :api_error }
    end

    account = parse_json(lookup.body)
    account_id = account['id']
    if account_id.blank?
      return { success: false, error: :not_found }
    end

    statuses = conn.get("/api/v1/accounts/#{account_id}/statuses", { limit: limit })
    unless statuses.status == 200
      return { success: false, error: :api_error }
    end

    list = parse_json(statuses.body)
    unless list.is_a?(Array)
      return { success: false, error: :parse_error }
    end

    items = list.filter_map { |status| build_preview_item(status) }.first(limit)
    { success: true, items: items }
  rescue Faraday::TimeoutError, Faraday::ConnectionFailed
    { success: false, error: :timeout }
  rescue Faraday::Error
    { success: false, error: :network }
  rescue JSON::ParserError
    { success: false, error: :parse_error }
  end

  private

  def build_connection
    return @forced_connection if @forced_connection

    Faraday.new(url: "https://#{@instance_host}", request: { open_timeout: CONNECT_TIMEOUT, timeout: READ_TIMEOUT }) do |f|
      f.adapter Faraday.default_adapter
    end
  end

  def parse_json(body)
    JSON.parse(body.to_s)
  end

  def build_preview_item(status)
    return nil unless status.is_a?(Hash)

    url = status['url'].presence
    return nil if url.blank?

    html = status['content'].to_s
    plain = ActionController::Base.helpers.strip_tags(html).squish
    return nil if plain.blank?

    text = plain.truncate(PREVIEW_LENGTH, omission: '…')
    { text: text, url: url }
  end
end
