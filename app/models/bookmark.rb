class Bookmark < ActiveRecord::Base
  include Crud::ByUser

  belongs_to :user
end
