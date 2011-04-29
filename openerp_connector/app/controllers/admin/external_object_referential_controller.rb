class Admin::ExternalObjectReferentialController < Admin::BaseController
  resource_controller
  def ex_sincronize
    connect_openerp
    ex = ExternalObjectReferential.first
    ex.hash_to_erp
  end

  private
  def connect_openerp
      if not Ooor.default_ooor
        begin
          Ooor.default_ooor = Ooor.new(Ooor.load_config)
          puts Ooor.load_config
        rescue
          puts "OpenERP Error"
          #redirect_to :controller => 'openerp_connectors', :action => 'show'
        end
      end
  end
  def collection
    collection = ExternalObjectReferential.all
  end
  
  
end
