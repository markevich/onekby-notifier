class AddNotifyEmailToBots < ActiveRecord::Migration
  def change
    add_column :bots, :notification_email, :string
  end
end
