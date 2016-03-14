class Comment < ActiveRecord::Base
  belongs_to :Article
end
