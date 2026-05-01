require 'test_helper'

class LocalesParityTest < ActiveSupport::TestCase
  # Recursively flatten a nested hash into dotted keys.
  def flatten_keys(hash, prefix = nil)
    hash.flat_map do |key, value|
      path = [prefix, key].compact.join('.')
      value.is_a?(Hash) ? flatten_keys(value, path) : [path]
    end
  end

  def test_jaとenのキー集合が一致する
    ja = YAML.load_file(Rails.root.join('config/locales/ja.yml'))['ja']
    en = YAML.load_file(Rails.root.join('config/locales/en.yml'))['en']

    ja_keys = flatten_keys(ja).sort
    en_keys = flatten_keys(en).sort

    only_in_ja = ja_keys - en_keys
    only_in_en = en_keys - ja_keys

    assert_empty only_in_ja, "ja.yml にのみ存在するキー: #{only_in_ja.inspect}"
    assert_empty only_in_en, "en.yml にのみ存在するキー: #{only_in_en.inspect}"
  end
end
