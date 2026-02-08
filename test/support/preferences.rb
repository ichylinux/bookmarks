def preference_params(options = {})
  {
    use_todo: true,
    default_priority: options.fetch(:default_priority, Todo::PRIORITY_NORMAL)
  }
end
