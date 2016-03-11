class Article < ActiveRecord::Base
  belongs_to :Person, foreign_key: :writer_id

end
