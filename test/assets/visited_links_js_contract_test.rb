require 'test_helper'

class VisitedLinksJsContractTest < ActiveSupport::TestCase
  def setup
    @source = Rails.root.join('app/assets/javascripts/visited_links.js').read
  end

  test 'uses iife wrapper not document ready' do
    assert_includes @source, '(function () {'
    assert_includes @source, '})();'
    refute_match(/\$\(document\)\.ready|\$\(function/, @source)
  end

  test 'registers namespaced delegated handler on gadget links' do
    assert_includes @source, "$(document).on('click.visitedLinks', '.gadget ol li a[href]'"
  end

  test 'adds visited class before posting' do
    assert_includes @source, "addClass('link--visited')"
    assert_includes @source, "$.post('/visited_links'"
    assert @source.index("addClass('link--visited')") < @source.index("$.post('/visited_links'"),
           "addClass('link--visited') must appear before $.post('/visited_links') in source"
  end

  test 'includes authenticity_token in post params' do
    assert_includes @source, 'authenticity_token'
    assert_includes @source, "document.querySelector('meta[name=\"csrf-token\"]').content"
  end

  test 'strips fragment from href before posting' do
    assert_includes @source, "this.href.replace(/#.*$/, '')"
  end

  test 'does not prevent default — link navigates normally' do
    refute_includes @source, 'preventDefault'
  end

  test 'fire and forget — no fail handler' do
    refute_includes @source, '.fail('
  end

  test 'no window namespace export' do
    refute_match(/window\.\w+\s*=/, @source)
  end
end
