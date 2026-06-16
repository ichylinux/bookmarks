class MastodonHandleNormalizer
  Result = Struct.new(:handle, :error_key, keyword_init: true) do
    def success?
      error_key.nil?
    end
  end

  LOCALPART_PATTERN = /\A[a-z0-9_]{1,30}\z/i
  HOSTNAME_PATTERN = /\A[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])+)+\z/

  def self.normalize(input)
    new(input).normalize
  end

  def initialize(input)
    @input = input.to_s
  end

  def normalize
    stripped = @input.strip
    return Result.new(handle: nil, error_key: :blank) if stripped.blank?

    localpart, instance = parse(stripped)
    return failure(:missing_separator) if localpart.nil? && instance.nil? && stripped.include?('@')
    return failure(:invalid) unless valid_parts?(localpart, instance)

    Result.new(handle: "#{localpart}@#{instance.downcase}")
  end

  private

  def parse(value)
  return parse_url(value) if value.match?(%r{\A[a-z][a-z0-9+.-]*://}i)

    without_leading_at = value.sub(/\A@+/, '')
    return parse_at_user_at_instance(without_leading_at) if without_leading_at.count('@') >= 2

    parse_user_at_instance(without_leading_at)
  end

  def parse_url(value)
    without_scheme = value.sub(%r{\A[a-z][a-z0-9+.-]*://}i, '')
    host, path = without_scheme.split('/', 2)
    return [nil, nil] if path.present? && !path.match?(/\A@?[a-z0-9_]{1,30}\/?\z/i)

    localpart = path&.sub(/\A@/, '')&.delete_suffix('/')
    instance = host&.sub(/\A@+/, '')&.chomp('/')
    [localpart.presence, instance.presence]
  end

  def parse_at_user_at_instance(value)
    localpart, instance = value.split('@', 2)
    [localpart.presence, instance.presence]
  end

  def parse_user_at_instance(value)
    return [nil, nil] unless value.include?('@')

    at_index = value.rindex('@')
    localpart = value[0...at_index]
    instance = value[(at_index + 1)..]
    [localpart.presence, instance.presence]
  end

  def valid_parts?(localpart, instance)
    return false if localpart.blank? || instance.blank?
    return false if instance.include?('/')
    return false if instance.match?(/\A[a-z][a-z0-9+.-]*:/i)
    return false if ip_literal?(instance)

    localpart.match?(LOCALPART_PATTERN) && instance.downcase.match?(HOSTNAME_PATTERN)
  end

  def ip_literal?(value)
    return true if value.match?(/\A\d{1,3}(?:\.\d{1,3}){3}\z/)
    return true if value.include?(':')

    false
  end

  def failure(error_key)
    Result.new(error_key: error_key)
  end
end
