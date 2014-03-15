class CreateBots < ActiveRecord::Migration
  def change
    create_table :bots do |t|
      t.string :name
      t.string :auth_cookie

      t.timestamps
    end
  end
end
