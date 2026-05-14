# frozen_string_literal: true

# Prepends test-only stub seams onto XClient and MastodonClient so app/services
# stays free of test hooks. Loaded from config/environments/test.rb (Minitest + Cucumber).
return if defined?(HTTP_CLIENT_TEST_STUBS_INSTALLED) && HTTP_CLIENT_TEST_STUBS_INSTALLED

HTTP_CLIENT_TEST_STUBS_INSTALLED = true

module XClientTestStub
  def fetch_following(user:, max_results: 100)
    stubbed = normalize_following_stub(XClient.stub_fetch_following_result)
    return stubbed if stubbed

    super
  end

  def fetch_recent_tweets(user:, x_user_id:, limit:)
    stubbed = normalize_tweets_stub(XClient.stub_fetch_tweets_result)
    return stubbed if stubbed

    super
  end

  private

  def normalize_following_stub(stub)
    return nil if stub.nil?

    unless stub.is_a?(Hash)
      return { success: false, error: :api_error }
    end

    h = stub.with_indifferent_access
    if ActiveModel::Type::Boolean.new.cast(h[:success])
      items = Array(h[:items]).filter_map do |row|
        next unless row.is_a?(Hash)

        r = row.with_indifferent_access
        next if r[:id].blank? || r[:username].blank?

        {
          id: r[:id].to_s,
          username: r[:username].to_s,
          name: r[:name].to_s,
          profile_image_url: r[:profile_image_url].presence,
          protected: ActiveModel::Type::Boolean.new.cast(r[:protected])
        }
      end
      return { success: true, items: items }
    end

    err = h[:error].presence&.to_sym
    err = :api_error unless valid_error_symbol?(err)
    { success: false, error: err }
  end

  def normalize_tweets_stub(stub)
    return nil if stub.nil?

    unless stub.is_a?(Hash)
      return { success: false, error: :api_error }
    end

    h = stub.with_indifferent_access
    if ActiveModel::Type::Boolean.new.cast(h[:success])
      items = Array(h[:items]).filter_map do |row|
        next unless row.is_a?(Hash)

        r = row.with_indifferent_access
        next if r[:text].blank? || r[:url].blank?

        {
          text: r[:text].to_s.squish.truncate(XClient::PREVIEW_LENGTH, omission: '…'),
          url: r[:url].to_s
        }
      end
      return { success: true, items: items }
    end

    err = h[:error].presence&.to_sym
    err = :api_error unless valid_error_symbol?(err)
    { success: false, error: err }
  end

  def valid_error_symbol?(sym)
    %i[
      timeout network not_found api_error parse_error unauthorized rate_limited
    ].include?(sym)
  end
end

class << XClient
  attr_accessor :stub_fetch_following_result, :stub_fetch_tweets_result
end

XClient.prepend(XClientTestStub)

module MastodonClientTestStub
  def fetch_recent_status_previews(username:, limit:)
    stub = MastodonClient.stub_fetch_result
    return normalize_stub_result(stub) if stub

    super
  end

  private

  def normalize_stub_result(stub)
    return { success: false, error: :parse_error } unless stub.is_a?(Hash)

    h = stub.with_indifferent_access
    if ActiveModel::Type::Boolean.new.cast(h[:success])
      items = Array(h[:items]).filter_map do |row|
        next unless row.is_a?(Hash)

        r = row.with_indifferent_access
        next if r[:text].blank? || r[:url].blank?

        { text: r[:text].to_s, url: r[:url].to_s }
      end
      return { success: true, items: items }
    end

    err = h[:error].presence&.to_sym || :api_error
    { success: false, error: err }
  end
end

class << MastodonClient
  attr_accessor :stub_fetch_result
end

MastodonClient.prepend(MastodonClientTestStub)
