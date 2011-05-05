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
    Dir.glob(File.expand_path("../app/**/*_decorator.rb", __FILE__)).each do |file|
      (Rails.env == "production") ?  require(file) : load(file)
    end
  end
end
