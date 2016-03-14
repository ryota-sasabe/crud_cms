class Article < ActiveRecord::Base
  has_many :Comment
  belongs_to :Author, foreign_key: :author_id
end
