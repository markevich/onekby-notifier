class Category < ActiveRecord::Base
  belongs_to :bot

  validates :bot, :name, :max_bet, presence: true
end
