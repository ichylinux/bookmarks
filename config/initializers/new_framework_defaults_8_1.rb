# Be sure to restart your server when you modify this file.
#
# This file eases your Rails 8.1 framework defaults upgrade.
#
# Uncomment each configuration one by one to switch to the new default.
# Once your application is ready to run with all new defaults, you can remove
# this file and set the `config.load_defaults` to `8.1` in `config/application.rb`.
#
# Read the Guide for Upgrading Ruby on Rails for more info on each option.
# https://guides.rubyonrails.org/upgrading_ruby_on_rails.html

###
# Enables YJIT in non-local environments. YJIT is the Ruby JIT compiler that
# improves performance but is not needed for development/test.
#
# config.yjit = !Rails.env.local?

###
# Stop escaping HTML entities and certain Unicode characters in JSON output.
# Most JSON is consumed by API clients, not embedded in HTML script tags.
# This setting is deprecated and will have no effect in Rails 8.2.
#
# config.action_controller.escape_json_responses = false

###
# Raise an error when a controller attempts a path-relative redirect
# (e.g., `redirect_to "example.com"` without a leading slash).
# This is a security hardening change to prevent open redirect vulnerabilities.
#
# config.action_controller.action_on_path_relative_redirect = :raise

###
# Raise an error when using order-dependent finder methods (#first, #last, etc.)
# without an explicit ORDER BY clause.
#
# config.active_record.raise_on_missing_required_finder_order_columns = true

###
# Stop escaping JavaScript line/paragraph separators (U+2028, U+2029) in JSON.
# Modern browsers handle these correctly.
#
# config.active_support.escape_js_separators_in_json = false

###
# Switch the template dependency tracker from regex to the Ruby parser (Prism).
#
# config.action_view.render_tracker = :ruby

###
# Remove unnecessary autocomplete="off" attribute from hidden form fields.
#
# config.action_view.remove_hidden_field_autocomplete = true
