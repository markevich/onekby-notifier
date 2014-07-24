class ChangeCategories < ActiveRecord::Migration
  def change
    change_column :categories, :enabled, :boolean, default: false
    change_column :categories, :max_bet, :float, default: 50
  end
end
