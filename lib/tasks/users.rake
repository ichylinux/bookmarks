# frozen_string_literal: true

namespace :users do
  desc "アクティブユーザーを管理者にします（users.admin を true）。EMAIL または USER_ID を指定します。"
  task promote_admin: :environment do
    email = ENV['EMAIL']&.strip
    raw_id = ENV['USER_ID']&.strip

    if email.present? && raw_id.present?
      abort 'EMAIL と USER_ID の両方は指定しないでください。どちらか一方だけにしてください。'
    end

    user =
      if email.present?
        User.active.find_by('LOWER(email) = ?', email.downcase)
      elsif raw_id.present?
        User.active.find_by(id: raw_id.to_i)
      else
        warn 'Usage: EMAIL=user@example.com bin/rails users:promote_admin'
        warn '   or: USER_ID=123 bin/rails users:promote_admin'
        abort
      end

    unless user
      target = email.present? ? "email=#{email.inspect}" : "id=#{raw_id.inspect}"
      abort "該当するアクティブユーザーがありません (#{target})。削除済みのユーザーは対象にできません。"
    end

    if user.admin?
      puts "すでに管理者です: id=#{user.id} email=#{user.email}"
    else
      user.update!(admin: true)
      puts "管理者に設定しました: id=#{user.id} email=#{user.email}"
    end
  end
end
