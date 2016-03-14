class RenameColumnToArticle < ActiveRecord::Migration
  def change
    rename_column :articles, :writer_id, :author_id
  end
end
