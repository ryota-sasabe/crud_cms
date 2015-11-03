class CreateArticles < ActiveRecord::Migration
  def change
    create_table :articles do |t|
      t.string :title
      t.string :meta_keywords
      t.string :meta_description
      t.text :contents
      t.datetime :publish_date
      t.integer :writer_id
      t.timestamps null: false
      add_foreign_key :articles, :persons, column: :writer_id
    end
  end
end
