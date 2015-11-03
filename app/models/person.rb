class Person < ActiveRecord::Base
  has_many :articles, foreign_key: :writer_id
end
