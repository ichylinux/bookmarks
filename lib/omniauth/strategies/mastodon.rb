require 'json'
require 'faraday'

module OmniAuth
  module Strategies
    # Custom Mastodon OAuth 2.0 strategy with dynamic instance targeting and app registration.
    class Mastodon < OmniAuth::Strategies::OAuth2
      option :name, 'mastodon'

      option :client_options,
             authorize_url: '/oauth/authorize',
             token_url: '/oauth/token'

      uid { raw_info['id'].to_s }

      info do
        {
          name: raw_info['display_name'].presence || raw_info['username'],
          nickname: raw_info['username'],
          image: raw_info['avatar'],
          instance: session[:mastodon_instance]
        }.compact
      end

      def request_phase
        validate_mastodon_instance!
        register_application!
        super
      end

      def callback_phase
        validate_mastodon_instance!
        super
      end

      def client
        ::OAuth2::Client.new(client_id, client_secret, deep_symbolize(client_options))
      end

      def client_options
        options.client_options.merge(site: mastodon_site)
      end

      def raw_info
        @raw_info ||= begin
          response = access_token.get('/api/v1/accounts/verify_credentials')
          response.parsed
        rescue ::OAuth2::Error => e
          fail!(:invalid_credentials, e)
        end
      end

    private

      def client_id
        session[:mastodon_oauth_client_id].presence || options.client_id
      end

      def client_secret
        session[:mastodon_oauth_client_secret].presence || options.client_secret
      end

      def mastodon_site
        "https://#{session[:mastodon_instance]}"
      end

      def validate_mastodon_instance!
        return if session[:mastodon_instance].present?

        fail!(:invalid_credentials, StandardError.new('mastodon_instance is required'))
      end

      def register_application!
        return if oauth_credentials_cached_for_current_instance?

        response = Faraday.post("#{mastodon_site}/api/v1/apps") do |req|
          req.headers['Content-Type'] = 'application/json'
          req.body = {
            client_name: Rails.application.class.module_parent_name,
            redirect_uris: callback_url,
            scopes: 'read'
          }.to_json
        end

        unless response.success?
          body_snippet = response.body.to_s[0, 200]
          fail!(:invalid_credentials, StandardError.new("App registration failed (#{response.status}): #{body_snippet}"))
        end

        data = parse_registration_response!(response.body)
        session[:mastodon_oauth_client_id] = data['client_id']
        session[:mastodon_oauth_client_secret] = data['client_secret']
        session[:mastodon_oauth_instance] = session[:mastodon_instance]
      end

      def oauth_credentials_cached_for_current_instance?
        session[:mastodon_oauth_client_id].present? &&
          session[:mastodon_oauth_client_secret].present? &&
          session[:mastodon_oauth_instance] == session[:mastodon_instance]
      end

      def parse_registration_response!(body)
        data = JSON.parse(body)
        if data['client_id'].blank? || data['client_secret'].blank?
          fail!(:invalid_credentials, StandardError.new('App registration response missing client_id or client_secret'))
        end
        data
      rescue JSON::ParserError => e
        fail!(:invalid_credentials, StandardError.new("App registration returned invalid JSON: #{e.message}"))
      end
    end
  end
end
