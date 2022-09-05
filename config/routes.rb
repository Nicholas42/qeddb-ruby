Rails.application.routes.draw do
	get '/login', to: 'sessions#new'
	post '/login', to: 'sessions#create'
	delete '/logout', to: 'sessions#destroy'
	get '/logout', to: 'sessions#destroy'

	get '/export', to: 'export#prepare'
	post '/export', to: 'export#export'
	get '/import', to: 'import#prepare'
	post '/import', to: 'import#import'
	
	get '/admin', to: 'admin#show'

	resources :versions, only: [:index, :show] do
		patch 'revert', to: 'versions#revert', on: :member
	end

	concern :versionable do
		resources :versions, only: [:index, :show] do
			get 'diff', to: 'versions#diff'
			get 'diff/:after_id', to: 'versions#diff'
			patch 'revert', to: 'versions#revert'
		end
	end

	resources :password_resets # TODO only

	get '/people_as_table', to: 'people#index_as_table'
	get '/events_as_table', to: 'events#index_as_table'

	root 'static#index'
	
	resources :people, concerns: :versionable do
		member do
			get 'addresses'
			get 'registrations'
			get 'privacy'
			get 'payments'
      get 'sepa_mandate'
			get 'groups'
	
			get 'edit_addresses'
			get 'edit_privacy'
			get 'edit_payments'
      get 'edit_sepa_mandate'
			get 'edit_groups'
			
			get 'activate'
		end
	end
	
	resources :registrations, concerns: :versionable do
		member do
			post 'self', to: 'registrations#create_self'
			get 'self', to: 'registrations#edit_self'
			put 'self', to: 'registrations#update_self'
			patch 'self', to: 'registrations#update_self'
		end
	end
	
	resources :events, concerns: :versionable do
		member do
			get 'registrations_as_table'
			get 'edit_own_registration'
		end
		
		get 'register_other', to: 'registrations#select_person', as: 'select_person'
		post 'register_other', to: 'registrations#with_selected_person'
		get 'register_other/:person_id', to: 'registrations#new', as: 'register_person'
		post 'register_other/:person_id', to: 'registrations#create'
		get 'register_self', to: 'registrations#new_self'
		post 'register_self', to: 'registrations#create_self'
	end
	
	resources :hostels, concerns: :versionable
	resources :groups, concerns: :versionable
	resources :mailinglists, concerns: :versionable
	
	# For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
