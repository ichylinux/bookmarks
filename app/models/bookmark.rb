class Bookmark < ActiveRecord::Base
  include Crud::ByUser

  belongs_to :user
  acts_as_tree order: 'title'

  scope :folders, -> { where(url: nil) }
  scope :files, -> { where.not(url: nil) }

  validates :title, presence: true
  validate :url_validation
  validate :validate_nesting_depth

  def folder?
    url.nil? || url.blank?
  end

  def file?
    url.present?
  end

  def destroy_logically!
    update!(deleted: true)
  end

  private

  def url_validation
    if folder?
      # フォルダの場合はurlがnilまたは空文字列でなければならない
      if url.present?
        errors.add(:url, 'must be blank for folders')
      end
    else
      # ファイルの場合はurlが必須
      if url.blank?
        errors.add(:url, "can't be blank for files")
      end
    end
  end

  def validate_nesting_depth
    # フォルダはルートレベルでなければならない（parent_idはnil）
    if folder? && parent_id.present?
      errors.add(:parent_id, "folders must be at root level")
      return
    end

    return unless parent_id.present?

    # 自分自身を親に設定することはできない
    if parent_id == id
      errors.add(:parent_id, "can't be set to itself")
      return
    end
  end
end
