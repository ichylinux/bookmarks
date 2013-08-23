# coding: UTF-8

class Bookmark < ActiveRecord::Base
  belongs_to :user
end
