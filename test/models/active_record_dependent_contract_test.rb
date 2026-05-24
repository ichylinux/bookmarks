require 'test_helper'

# Regression guard: User lifecycle uses soft-delete (destroy_account!) and explicit
# purge! (delete_all in a transaction). dependent: :destroy / :delete_all on associations
# would cascade physical deletes from accidental user.destroy calls.
class ActiveRecordDependentContractTest < ActiveSupport::TestCase
  FORBIDDEN_DEPENDENT = /
    dependent:\s*:(destroy|delete_all)\b
  /x

  test 'app/models does not declare dependent destroy or delete_all' do
    violations = []

    Dir[Rails.root.join('app/models/**/*.rb')].sort.each do |path|
      rel = path.delete_prefix("#{Rails.root}/")
      File.readlines(path).each_with_index do |line, index|
        next unless FORBIDDEN_DEPENDENT.match?(line)

        violations << "#{rel}:#{index + 1}: #{line.strip}"
      end
    end

    assert_empty violations,
                 "Do not use dependent: :destroy or dependent: :delete_all on associations.\n" \
                 "Use soft-delete or explicit purge! cleanup instead.\n\n" \
                 "#{violations.join("\n")}"
  end
end
