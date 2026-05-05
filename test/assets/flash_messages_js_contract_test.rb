# frozen_string_literal: true

require 'test_helper'

class FlashMessagesJsContractTest < ActiveSupport::TestCase
  def setup
    @flash_messages_js = Rails.root.join('app/assets/javascripts/flash_messages.js').read
  end

  test 'flash dismiss control removes only the owning flash message' do
    assert_includes @flash_messages_js, "$(document).on('click', '[data-dismiss-flash]'"
    assert_includes @flash_messages_js, "$(this).closest('.flash-message').remove();"
  end
end
