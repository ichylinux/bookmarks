def preference_params(options = {})
  {
    :use_two_factor_authentication => false,
    :use_todo => true,
    :default_priority => options.fetch(:default_priority, Todo::PRIORITY_NORMAL)
  }
end
