def mastodon_account_of(user_id)
  MastodonAccount.where(user_id: user_id).not_deleted.first
end

def mastodon_account_params
  {
    profile_url: 'https://ruby.social/@TestUser',
    display_count: 7
  }
end
