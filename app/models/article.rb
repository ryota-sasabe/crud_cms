class Article < ActiveRecord::Base
  belongs_to :person, foreign_key: :writer_id

end
