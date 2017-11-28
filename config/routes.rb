# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

scope '/projects/:project_id/team_dashboard' do
  get '/', to: 'dashboard#index'
  post '/', to: 'dashboard#index'
  match 'upload_image', to: 'dashboard#upload_image', via: :post
  match 'remove_image', to: 'dashboard#remove_image', via: :post

  get '/team_management', to: 'team_management#index'
  post 'team_management/update', to: 'team_management#update'
end
