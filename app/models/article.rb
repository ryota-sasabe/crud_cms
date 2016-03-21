class Article < ActiveRecord::Base
  has_many :Comment
  has_many :tags, through: :articles_tags
  belongs_to :Author, foreign_key: :author_id
end
