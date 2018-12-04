# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

scope '/projects/:project_id/team_dashboard' do
  get '/', to: 'dashboard#index'
  post '/', to: 'dashboard#index'
  get 'edit_configuration/:id', to: 'dashboard#edit_configuration'
  get 'new_configuration', to: 'dashboard#new_configuration'
  post 'save_configuration', to: 'dashboard#save_configuration'
  get 'remove_configuration/:id', to: 'dashboard#remove_configuration'
  get 'load_configuration/:id', to: 'dashboard#load_configuration'

  get '/team_management', to: 'team_management#index'
  post 'team_management/update', to: 'team_management#update'

  resources :user_files, path: '/:file_kind', only: [:show, :destroy], param: 'user_id' do
    member do
      post 'create'
    end
  end
end
