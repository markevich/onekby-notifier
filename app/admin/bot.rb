ActiveAdmin.register Bot do
  permit_params :name, :auth_user_id, :auth_session_id, :notification_email

  index do
    selectable_column
    id_column
    column :name
    column :notification_email
    column :updated_at
    actions
  end

  form do |f|
    f.inputs "Bot Details" do
      f.input :name
      f.input :notification_email, as: :email
      f.input :auth_user_id
      f.input :auth_session_id
    end
    f.actions
  end
end
