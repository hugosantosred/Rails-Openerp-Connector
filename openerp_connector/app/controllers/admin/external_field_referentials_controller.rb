class Admin::ExternalFieldReferentialsController < Admin::BaseController
  resource_controller
  belongs_to :external_object_referential
end
