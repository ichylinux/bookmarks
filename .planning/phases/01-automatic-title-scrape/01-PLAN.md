# Phase 1: Automatic Title Scrape for New Bookmark

**Goal:** When a user blurs the URL field on the new bookmark form, silently fetch the page's `<title>` tag via a server-side proxy and pre-fill the title input if it is currently empty.

**Approach:** Add a `GET /bookmarks/fetch_title` collection route and a corresponding `BookmarksController#fetch_title` action that uses Faraday + Nokogiri to scrape the remote page title, returning it as plain text (or an empty 200 on any error). Add `app/assets/javascripts/bookmarks.js` that binds a `blur` handler on `#bookmark_url` and, on a successful non-empty response, writes the title to `#bookmark_title` only when that field is currently blank. No new gems are required — Faraday and Nokogiri are already in the Gemfile.

---

## Tasks

### Task 1: Add route for `fetch_title`

**File:** `config/routes.rb`
**Action:** modify

Inside the existing `resources :bookmarks` block (currently a bare `resources :bookmarks` on line 17), add a `collection` block with a `get 'fetch_title'` entry so that the route resolves to `GET /bookmarks/fetch_title`.

Before:
```ruby
resources :bookmarks
```

After:
```ruby
resources :bookmarks do
  collection do
    get 'fetch_title'
  end
end
```

The convention mirrors the `feeds` resource directly below it:
```ruby
resources :feeds do
  collection do
    post 'get_feed_title'
  end
end
```

**Verification:** Run `bin/rails routes | grep fetch_title` and confirm a line containing `GET /bookmarks/fetch_title(.:format) bookmarks#fetch_title` appears.

---

### Task 2: Add `BookmarksController#fetch_title` action

**File:** `app/controllers/bookmarks_controller.rb`
**Action:** modify

Make two changes to this file:

**2a. Add `fetch_title` to the `before_action :preload_bookmark` exclusion list** — the action does not operate on a specific bookmark record, so it must not be included in `preload_bookmark`. The existing `before_action` line already lists the only actions that need it, so no change is required there. However, `ApplicationController` (parent class) enforces `authenticate_user!` globally for all controllers, so authentication is already covered. Confirm this by checking `ApplicationController` — if `before_action :authenticate_user!` is present there, no additional line is needed in `BookmarksController`. If it is not present globally, add `before_action :authenticate_user!, only: [:fetch_title]` at the top of the `before_action` declarations in `BookmarksController`.

**2b. Add the `fetch_title` action** in the public section of the controller, before the `private` keyword. Insert the following method:

```ruby
def fetch_title
  url = params[:url].to_s.strip
  raise ArgumentError, 'blank url' if url.blank?

  conn = Faraday.new do |f|
    f.options.timeout      = 5
    f.options.open_timeout = 5
    f.response :follow_redirects
  end

  response = conn.get(url)
  title = Nokogiri::HTML(response.body).at('title')&.text&.strip
  raise 'no title' if title.blank?

  render plain: title
rescue StandardError
  head :ok
end
```

Key points:
- `params[:url]` comes from the query string (`?url=<encoded-url>`).
- The `rescue StandardError` block catches network errors, timeouts, parse errors, and the `ArgumentError`/`RuntimeError` raised explicitly above — all return an empty 200.
- `f.response :follow_redirects` requires `faraday_middleware` (already in Gemfile) — Faraday 2.x bundles follow-redirects natively; use `f.response :follow_redirects` for either version.
- No `render` or `redirect_to` inside the rescue block other than `head :ok`.

**Verification:** Start the Rails server and run:
```
curl -s "http://localhost:3000/bookmarks/fetch_title?url=https://example.com"
```
Expect the string `Example Domain` (or similar) in the response body. Then run:
```
curl -o /dev/null -w "%{http_code}" "http://localhost:3000/bookmarks/fetch_title?url=http://definitely-does-not-exist.invalid"
```
Expect `200` with an empty body.

---

### Task 3: Add `app/assets/javascripts/bookmarks.js`

**File:** `app/assets/javascripts/bookmarks.js`
**Action:** create (new file)

Create the file with the following exact content, following the `feeds.js` namespace pattern:

```javascript
var bookmarks = {};

$(document).on('turbolinks:load', function() {
  $(document).on('blur', '#bookmark_url', function() {
    var urlValue = $.trim($(this).val());
    if (urlValue === '') {
      return;
    }

    $.get('/bookmarks/fetch_title', { url: urlValue })
      .done(function(title) {
        title = $.trim(title);
        if (title === '') {
          return;
        }
        var $titleField = $('#bookmark_title');
        if ($.trim($titleField.val()) === '') {
          $titleField.val(title);
        }
      })
      .fail(function() {
        // silent — do nothing
      });
  });
});
```

Implementation notes:
- `$(document).on('turbolinks:load', ...)` is the correct lifecycle event for Turbolinks-enabled Rails apps (same as the pattern expected by this codebase). If Turbolinks is not present, `$(document).ready(...)` is the fallback — check `application.js` for `require turbolinks`; it is not present in the current manifest, so use `$(document).ready(function() { ... })` instead of `turbolinks:load`. Based on the current `application.js`, **use `$(document).ready`**.
- The `blur` event is bound via event delegation on `document` so it works after Turbolinks navigations and after the DOM is ready without rebinding.
- `#bookmark_url` and `#bookmark_title` are the IDs generated by `f.text_field :url` and `f.text_field :title` in `app/views/bookmarks/_form.html.erb` (Rails generates `id` from the model name + attribute name: `bookmark_url`, `bookmark_title`).
- The "locked-unless-blank" rule: only write the fetched title if `#bookmark_title` is currently empty. If the user has already typed something, skip.
- `.fail()` does nothing — silent failure as required.

**Verification:** Load the new bookmark form in a browser (`/bookmarks/new`). Enter a valid URL (e.g. `https://example.com`) in the URL field, then tab/click away. The Title field should populate automatically. If the Title field already has text, it must not be overwritten. Entering an unreachable URL must leave the Title field blank with no error shown.

---

### Task 4: Confirm asset pipeline inclusion

**File:** `app/assets/javascripts/application.js`
**Action:** verify (no edit required)

The current `application.js` manifest ends with `//= require_tree .`, which automatically includes every `.js` file in the `app/assets/javascripts/` directory — including the newly created `bookmarks.js`. **No manual `//= require bookmarks` line is needed or should be added** (adding it alongside `require_tree .` would cause the file to be included twice).

**Verification:** After creating `bookmarks.js`, run:
```
bin/rails assets:precompile 2>&1 | grep -i bookmarks
```
Confirm the command succeeds without error and that `bookmarks` appears in the compiled asset list. Alternatively, load any page in development and open browser DevTools → Sources; confirm `bookmarks.js` is loaded.
