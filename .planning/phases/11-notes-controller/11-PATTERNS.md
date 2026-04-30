# Phase 11 — Pattern Map — Notes Controller

## PATTERN MAPPING COMPLETE

---

## Target files (this phase)

| File | Role |
|------|------|
| `config/routes.rb` | Narrow `resources :notes` to `only: [:create]` |
| `app/controllers/notes_controller.rb` | New — `create` action |
| `test/controllers/notes_controller_test.rb` | New — integration coverage |

---

## Analog: strong params + user merge

**Source:** `app/controllers/todos_controller.rb`

```ruby
def todo_params
  ret = params.require(:todo).permit(:title, :priority)
  case action_name
  when 'create'
    ret = ret.merge(user_id: current_user.id)
  end
  ret
end
```

**Apply to notes:** `params.require(:note).permit(:body).merge(user_id: current_user.id)` inside `note_params` (only `create` exists — merge always on create path).

---

## Analog: integration test harness

**Source:** `test/controllers/bookmarks_controller_test.rb`

- `sign_in user` from `Devise::Test::IntegrationHelpers`
- `post collection_path, params: { bookmark: {...} }`
- Japanese test names permitted (`test_★` pattern)

---

## Analog: authenticate_user! baseline

**Source:** `app/controllers/application_controller.rb`

```ruby
before_action :authenticate_user!
```

`NotesController` inherits — **do not redefine** authentication unless overriding for a skipped action (not needed — single `create`).

---
