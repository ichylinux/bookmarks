# Be sure to restart your server when you modify this file.
#
# This file eases your Rails 6.1 framework defaults upgrade.
#
# Uncomment each configuration one at a time to switch from the defaults
# that shipped with Rails 6.0 to the new defaults in Rails 6.1.
#
# Read the Guide for Upgrading Ruby on Rails for more info on each option.
# https://guides.rubyonrails.org/upgrading_ruby_on_rails.html

# Support for inversing belongs_to -> has_many Active Record associations.
# Rails.application.config.active_record.has_many_inversing = true

# Track Active Storage variants in the database.
# Rails.application.config.active_storage.track_variants = true

# Apply random variation to the delay when retrying failed jobs.
# Rails.application.config.active_job.retry_jitter = 0.15

# Stop executing `after_enqueue`/`after_perform` callbacks if
# a preceding `before_enqueue`/`before_perform` callback halts with `throw :abort`.
# Rails.application.config.active_job.skip_after_callbacks_if_terminated = true

# Specify cookies SameSite protection level: either :none, :lax, or :strict.
#
# This change is not backwards compatible with earlier Rails versions.
# It's best enabled when your entire app is migrated and stable on 6.1.
# Rails.application.config.action_dispatch.cookies_same_site_protection = :lax

# Generate CSRF tokens that are encoded in URL-safe Base64.
#
# This change is not backwards compatible with earlier Rails versions.
# It's best enabled when your entire app is migrated and stable on 6.1.
# Rails.application.config.action_controller.urlsafe_csrf_tokens = true

# Specify whether `ActiveSupport::TimeZone.utc_to_local` returns a time with an
# UTC offset or a UTC time.
# Rails.application.config.active_support.utc_to_local_returns_utc_offset_times = true

# Change the default HTTP status code to `308` when redirecting non-GET/HEAD
# requests to HTTPS in `ActionDispatch::SSL` middleware.
# Rails.application.config.action_dispatch.ssl_default_redirect_status = 308

# Use a SHA-256 hash digest for Active Support.
# This change is not backwards compatible with earlier Rails versions.
# Rails.application.config.active_support.hash_digest_class = OpenSSL::Digest::SHA256

# Make `form_with` generate non-remote forms by default.
# Rails.application.config.action_view.form_with_generates_remote_forms = false

# Set the default queue name for the analysis job to the queue adapter default.
# Rails.application.config.active_storage.queues.analysis = nil

# Set the default queue name for the purge job to the queue adapter default.
# Rails.application.config.active_storage.queues.purge = nil

# Set the default queue name for the mail delivery job to the queue adapter default.
# Rails.application.config.action_mailer.deliver_later_queue_name = nil
