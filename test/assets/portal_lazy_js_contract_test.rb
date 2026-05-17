require 'test_helper'

class PortalLazyJsContractTest < ActiveSupport::TestCase
  def setup
    @source = Rails.root.join('app/assets/javascripts/portal_lazy.js').read
  end

  test 'window.portalLazy namespace is declared at top level' do
    assert_includes @source, 'window.portalLazy = window.portalLazy || {};'
    assert_includes @source, 'const portalLazy = window.portalLazy;'
  end

  test 'register and loadColumn are exposed on portalLazy' do
    assert_includes @source, 'portalLazy.register = function(columnIndex, loadFn)'
    assert_includes @source, 'portalLazy.loadColumn = function(index)'
  end

  test 'mobile viewport guard uses exact 767px breakpoint' do
    assert_includes @source, "window.matchMedia('(max-width: 767px)').matches"
  end

  test 'initial column index is read from css custom property at parse time' do
    assert_includes @source, "getPropertyValue('--portal-initial-active-index')"
    assert_includes @source, 'Number.isNaN(parsed) || parsed < 0'
  end

  test 'load state is marked synchronously before dispatching load functions' do
    assert_match(/loadedColumns\[index\] = true;.*const fns/m, @source)
  end

  test 'already-loaded columns call loadFn directly in register' do
    assert_includes @source, 'if (loadedColumns[columnIndex])'
    assert_match(/if \(loadedColumns\[columnIndex\]\) \{\s*loadFn\(\);/m, @source)
  end

  test 'desktop pass-through fires loadFn immediately' do
    assert_match(/if \(!isMobileViewport\(\)\) \{\s*loadFn\(\);/m, @source)
  end

  test 'module uses iife not document ready wrapper' do
    refute_match(/\$\(document\)\.ready|\$\(function/, @source)
    assert_includes @source, '(function() {'
    assert_includes @source, '})();'
  end

  test 'no var keyword present' do
    refute_match(/\bvar\b/, @source)
  end
end
