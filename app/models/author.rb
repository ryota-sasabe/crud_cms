class Author < ActiveRecord::Base
  has_many :Article
end
