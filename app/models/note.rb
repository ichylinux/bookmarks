class Note < ActiveRecord::Base
  include Crud::ByUser

  belongs_to :user

  before_validation :strip_body

  validates :body, presence: true, length: { maximum: 4000 }

  scope :recent, -> { order(created_at: :desc) }

  def destroy_logically!
    update!(deleted: true)
  end

  private

  def strip_body
    body&.strip!
  end
end
