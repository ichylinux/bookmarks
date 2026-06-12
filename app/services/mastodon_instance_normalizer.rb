class MastodonInstanceNormalizer
  Result = Struct.new(:hostname, :error_key, keyword_init: true) do
    def success?
      error_key.nil?
    end
  end

  HOSTNAME_PATTERN = /\A[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])+)+\z/

  def self.normalize(input)
    new(input).normalize
  end

  def initialize(input)
    @input = input.to_s
  end

  def normalize
    stripped = strip_input(@input)
    return failure(:blank) if stripped.blank?
    return failure(:invalid) if stripped.include?('/')
    return failure(:invalid) if stripped.match?(/\A[a-z][a-z0-9+.-]*:/i)
    return failure(:invalid) if ip_literal?(stripped)

    hostname = stripped.downcase
    return failure(:invalid) unless hostname.match?(HOSTNAME_PATTERN)

    Result.new(hostname: hostname)
  end

  private

  def strip_input(value)
    value.strip
         .sub(%r{\Ahttps?://}i, '')
         .sub(/\A@+/, '')
         .chomp('/')
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
