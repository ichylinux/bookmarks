class Retweet < ApplicationRecord
  belongs_to :tweet, inverse_of: 'retweets'
end
