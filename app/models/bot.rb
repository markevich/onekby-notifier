class Bot < ActiveRecord::Base
  validates :name, :auth_user_id, :auth_session_id, :notification_email, presence: true

  has_many :categories
end
