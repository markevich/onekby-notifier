ActiveAdmin.register Category do
  permit_params :name, :max_bet, :enabled, :bot_id

  index do
    id_column
    column :bot
    column :name
    column :enabled
    column :max_bet
    column :updated_at
    actions
  end

  form do |f|
    f.inputs "Category details" do
      f.input :bot
      f.input :name
      f.input :enabled
      f.input :max_bet
    end
    f.actions
  end
end
