# This migration comes from active_crud (originally 20151112082743)
class CreateActiveCrudTests < ActiveRecord::Migration
  def change
    create_table :active_crud_tests do |t|
      t.string :name

      t.timestamps null: false
    end
  end
end
