class Person < ActiveRecord::Base
  has_many :Article, foreign_key: :writer_id
end
