class ExternalReferentialId < ActiveRecord::Base
  def ir_model_data(erp_model)
    erp_object = erp_model.gsub('_','.')
    name = "#{erp_object}_#{self.rails_id}"
    ir_model = IrModelData.find(:first, :domain => [['name','=',name],['res_id','=',self.openerp_id],['external_referential_id','=',1]])
    if !ir_model
      ir_model = IrModelData.new(:name => name, :module => "extref.tienda1", :res_id => self.openerp_id, :external_referential_id => 1, :model => erp_object)
      ir_model.save
    end
    ir_model
  end
end
