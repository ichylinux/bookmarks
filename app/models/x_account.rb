# frozen_string_literal: true

class XAccount < ApplicationRecord
  include Crud::ByUser

  MAX_SELECTION = 12
  SOFT_WARNING_AT = 9

  belongs_to :user

  before_save :set_display_count_default

  validates :x_user_id, presence: true
  validates :username, presence: true
  validates :display_count, numericality: { only_integer: true, greater_than: 0 }
  validate :selection_cap, if: :selected?
  validate :protected_acknowledgement, if: :selected?

  def gadget_id
    "x_account_#{id}"
  end

  def profile_url
    "https://x.com/#{username}"
  end

  def title
    display_name.presence || "@#{username}"
  end

  # Applies XClient following payload: upsert rows, soft-delete missing selected pins, hard-delete others.
  def self.refresh_cache_from_items!(user, items, refreshed_at: Time.current)
    user.transaction do
      seen = {}

      Array(items).each do |row|
        row = row.with_indifferent_access
        xid = row[:id].to_s
        next if xid.blank?

        seen[xid] = true
        acc = XAccount.where(user_id: user.id, x_user_id: xid).first_or_initialize
        acc.assign_attributes(
          username: row[:username].to_s,
          display_name: row[:name].to_s,
          avatar_url: row[:profile_image_url].presence,
          protected: ActiveModel::Type::Boolean.new.cast(row[:protected]),
          deleted: false
        )
        acc.save!
      end

      XAccount.where(user_id: user.id).find_each do |acc|
        next if seen[acc.x_user_id]

        if acc.selected?
          acc.update!(deleted: true)
        else
          acc.destroy!
        end
      end

      user.update_column(:x_accounts_last_refreshed_at, refreshed_at)
    end
  end

  def self.selected_count_for(user)
    where(user_id: user.id).not_deleted.where(selected: true).count
  end

  private

  def set_display_count_default
    self.display_count = 5 if display_count.to_i <= 0
  end

  def selection_cap
    scope = user.x_accounts.not_deleted.where(selected: true)
    scope = scope.where.not(id: id) if persisted?
    errors.add(:selected, :too_many) if scope.count >= MAX_SELECTION
  end

  def protected_acknowledgement
    return unless protected?
    return if protected_acknowledged?

    errors.add(:selected, :protected_not_acknowledged)
  end
end
