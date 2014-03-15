class AddAuthUserIdToBots < ActiveRecord::Migration
  def change
    add_column :bots, :auth_user_id, :string
    rename_column :bots, :auth_cookie, :auth_session_id
  end
end
