def gmail
  @_gmail ||= Gmail.first
end

def gmail_params
  {
    title: 'Gmail inbox',
    labels: 'INBOX UNREAD',
    display_count: 10
  }
end

def invalid_gmail_params
  {
    title: ''
  }
end
