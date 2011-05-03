# Put your extension routes here.

map.namespace :admin do |admin|
  admin.resources :external_object_referentials, :has_many => [:external_field_referentials]
  admin.resources :external_field_referentials
end  
