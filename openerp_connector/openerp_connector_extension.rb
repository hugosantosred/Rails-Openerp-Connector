# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

class OpenerpConnectorExtension < Spree::Extension
  version "1.0"
  description "Describe your extension here"
  url "http://yourwebsite.com/openerp_connector"

  # Please use openerp_connector/config/routes.rb instead for extension routes.

  def self.require_gems(config)
     config.gem "ooor"
  end
  
  def activate

    # make your helper avaliable in all views
    # Spree::BaseController.class_eval do
    #   helper YourHelper
    # end
  end
end
