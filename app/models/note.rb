class Note < ApplicationRecord
  include Crud::ByUser

  belongs_to :user

  before_validation :strip_body

  validates :body, presence: true, length: { maximum: 4000 }

  scope :active, -> { where(deleted: false) }
  scope :recent, -> { order(created_at: :desc) }

  private

  def strip_body
    body&.strip!
  end
end
