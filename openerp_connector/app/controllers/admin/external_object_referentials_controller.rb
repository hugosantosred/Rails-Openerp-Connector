class Admin::ExternalObjectReferentialsController < Admin::BaseController
  resource_controller

  def ex_sincronize
    connect_openerp
    ex_objs = ExternalObjectReferential.all
    ex_objs.each do |ex|
      ex.ext_export
    end
  end

  def in_sincronize
    connect_openerp
    in_objs = ExternalObjectReferential.all
    in_objs.each do |int|
      int.ext_import
    end
  end


  private
  def connect_openerp
    if not Ooor::Ooor.default_ooor
      begin
        Ooor::Ooor.default_ooor = Ooor.new(Ooor::Ooor.load_config)
        #puts Ooor.load_config
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