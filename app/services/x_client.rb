# X (Twitter) API v2 client. Authenticates via OAuth 2.0 Bearer token (oauth2_token).
class XClient
  CONNECT_TIMEOUT = 3
  READ_TIMEOUT = 5
  PREVIEW_LENGTH = 100

  def initialize(connection: nil)
    @forced_connection = connection
  end

  # Returns { success: true, items: [...] } or { success: false, error: Symbol }
  # Each following item: { id:, username:, name:, profile_image_url:, protected: }
  def fetch_following(user:, max_results: 100)
    uid = user.uid.to_s.presence
    return { success: false, error: :api_error } if uid.blank?

    per_page = [max_results.to_i, 5].max.clamp(5, 100)
    items = []
    next_token = nil
    loop do
      path = "/2/users/#{uid}/following"
      res = following_connection(user).get(path) do |req|
        req.params['max_results'] = per_page
        req.params['pagination_token'] = next_token if next_token.present?
        req.params['user.fields'] = 'id,name,username,profile_image_url,protected'
      end

      parsed = parse_following_response(res)
      return parsed unless parsed[:success]

      payload = parsed[:payload]
      Array(payload['data']).each do |row|
        next unless row.is_a?(Hash)

        items << normalize_following_row(row)
      end

      next_token = payload.dig('meta', 'next_token')
      break if next_token.blank?
    end

    { success: true, items: items }
  rescue Faraday::TimeoutError, Faraday::ConnectionFailed
    { success: false, error: :timeout }
  rescue Faraday::Error
    { success: false, error: :network }
  rescue JSON::ParserError
    { success: false, error: :parse_error }
  end

  # Returns { success: true, items: [{ text:, url: }, ...] } or { success: false, error: Symbol }
  def fetch_recent_tweets(user:, x_user_id:, limit:)
    xid = x_user_id.to_s.presence
    return { success: false, error: :not_found } if xid.blank?

    lim = limit.to_i.clamp(1, 100)
    # X API requires max_results >= 5; request the minimum if lim is below it
    api_lim = [lim, 5].max
    qs = []
    qs << "max_results=#{api_lim}"
    %w[retweets replies].each { |ex| qs << "exclude=#{ex}" }
    qs << 'tweet.fields=entities,edit_history_tweet_ids'
    path = "/2/users/#{xid}/tweets?#{qs.join('&')}"

    res = connection_for(user).get(path)
    result = parse_tweets_response(res)
    return result unless result[:success]

    result.merge(items: result[:items].first(lim))
  rescue Faraday::TimeoutError, Faraday::ConnectionFailed
    { success: false, error: :timeout }
  rescue Faraday::Error
    { success: false, error: :network }
  rescue JSON::ParserError
    { success: false, error: :parse_error }
  end

  # Returns { success: true, item: { id:, username:, name:, profile_image_url:, protected: } }
  # or { success: false, error: Symbol }
  # Error symbols: :not_found, :suspended, :rate_limited, :api_error
  def lookup_user_by_username(user:, username:)
    handle = username.to_s.sub(/\A@/, '').presence
    return { success: false, error: :not_found } if handle.blank?

    res = following_connection(user).get("/2/users/by/username/#{handle}") do |req|
      req.params['user.fields'] = 'id,name,username,profile_image_url,protected'
    end

    parse_lookup_response(res)
  rescue Faraday::TimeoutError, Faraday::ConnectionFailed
    { success: false, error: :api_error }
  rescue Faraday::Error
    { success: false, error: :api_error }
  end

  private

  def following_connection(user)
    return @forced_connection if @forced_connection

    connection_for(user)
  end

  def connection_for(user)
    refresh_if_expired!(user)
    bearer_faraday('https://api.twitter.com', user)
  end

  def bearer_faraday(base_url, user)
    Faraday.new(url: base_url, request: { open_timeout: CONNECT_TIMEOUT, timeout: READ_TIMEOUT }) do |f|
      f.headers['Authorization'] = "Bearer #{user.oauth2_token}"
      f.adapter Faraday.default_adapter
    end
  end

  def refresh_if_expired!(user)
    return unless user.oauth2_token_expires_at.present? &&
                  user.oauth2_token_expires_at <= Time.current + 60.seconds

    refresh_oauth2_token!(user)
  end

  def refresh_oauth2_token!(user)
    return unless user.oauth2_refresh_token.present?

    ck = Rails.application.config.app_config.omniauth_twitter2_client_id.to_s
    cs = Rails.application.config.app_config.omniauth_twitter2_client_secret.to_s
    return if ck.blank? || cs.blank?

    conn = Faraday.new(url: 'https://api.x.com') do |f|
      f.request :url_encoded
      f.adapter Faraday.default_adapter
    end

    res = conn.post('/2/oauth2/token') do |req|
      req.headers['Authorization'] = "Basic #{Base64.strict_encode64("#{ck}:#{cs}")}"
      req.body = { grant_type: 'refresh_token', refresh_token: user.oauth2_refresh_token, client_id: ck }
    end

    return unless res.status == 200

    body = parse_json_safe(res.body)
    return unless body.is_a?(Hash) && body['access_token'].present?

    expires_in = body['expires_in']
    expires_at = expires_in ? Time.current + expires_in.to_i.seconds : nil
    user.assign_attributes(
      oauth2_token: body['access_token'],
      oauth2_refresh_token: body['refresh_token'] || user.oauth2_refresh_token,
      oauth2_token_expires_at: expires_at
    )
    user.save(validate: false)
  rescue Faraday::Error, JSON::ParserError
    nil
  end

  def parse_following_response(res)
    case res.status
    when 200
      body = parse_json_safe(res.body)
      return { success: false, error: :parse_error } unless body.is_a?(Hash)

      { success: true, payload: body }
    when 401
      { success: false, error: :unauthorized }
    when 404
      { success: false, error: :not_found }
    when 429
      { success: false, error: :rate_limited }
    else
      { success: false, error: :api_error }
    end
  end

  def parse_tweets_response(res)
    case res.status
    when 200
      body = parse_json_safe(res.body)
      return { success: false, error: :parse_error } unless body.is_a?(Hash)

      list = Array(body['data'])
      items = list.filter_map { |tweet| build_tweet_preview(tweet) }
      { success: true, items: items }
    when 401
      { success: false, error: :unauthorized }
    when 404
      { success: false, error: :not_found }
    when 429
      { success: false, error: :rate_limited }
    else
      { success: false, error: :api_error }
    end
  end

  def parse_lookup_response(res)
    case res.status
    when 200
      body = parse_json_safe(res.body)
      return { success: false, error: :parse_error } unless body.is_a?(Hash)

      row = body['data']
      return { success: false, error: :not_found } unless row.is_a?(Hash)

      { success: true, item: normalize_following_row(row) }
    when 400, 404
      { success: false, error: :not_found }
    when 403
      { success: false, error: :suspended }
    when 429
      { success: false, error: :rate_limited }
    else
      { success: false, error: :api_error }
    end
  end

  def parse_json_safe(raw)
    JSON.parse(raw.to_s)
  rescue JSON::ParserError
    nil
  end

  def normalize_following_row(row)
    {
      id: row['id'].to_s,
      username: row['username'].to_s,
      name: row['name'].to_s,
      profile_image_url: row['profile_image_url'].presence,
      protected: ActiveModel::Type::Boolean.new.cast(row['protected'])
    }
  end

  def build_tweet_preview(tweet)
    return nil unless tweet.is_a?(Hash)

    text = tweet['text'].to_s
    text = expand_tco_entities(text, tweet['entities'])
    text = text.squish.truncate(PREVIEW_LENGTH, omission: '…')
    return nil if text.blank?

    tid = latest_tweet_id(tweet)
    return nil if tid.blank?

    { text: text, url: "https://x.com/i/status/#{tid}" }
  end

  def latest_tweet_id(tweet)
    ids = tweet['edit_history_tweet_ids']
    if ids.is_a?(Array) && ids.last.present?
      ids.last.to_s
    else
      tweet['id'].to_s
    end
  end

  def expand_tco_entities(text, entities)
    return text if text.blank? || !entities.is_a?(Hash)

    urls = Array(entities['urls'])
    return text if urls.empty?

    sorted = urls.sort_by { |u| -(u['start'].to_i) }
    out = text.dup
    sorted.each do |u|
      start = u['start'].to_i
      nxt = u['end'].to_i
      display = u['display_url'].presence || u['expanded_url'].presence
      next if display.blank?
      next if start.negative? || nxt > out.length || start >= nxt

      out[start...nxt] = display
    end
    out
  end
end
