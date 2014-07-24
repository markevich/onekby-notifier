class CreateCategories < ActiveRecord::Migration
  def change
    create_table :categories do |t|
      t.integer :bot_id
      t.boolean :enabled
      t.string :name
      t.float :max_bet

      t.timestamps
    end
  end
end
