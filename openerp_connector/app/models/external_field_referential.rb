class ExternalFieldReferential < ActiveRecord::Base
  belongs_to :external_object_referential
  has_one :referenced_object, :class => "ExternalObjectReferential", :foreign_key => :referenced_object_id
  
  #Convierte campos uno a muchos de rails a ids de openerp
  def one2many_conversion(rails_id)
    ext_object = self.external_object_referential
    rails_obj = eval(ext_object).find(rails_id)
    referenced_object = field.referenced_object
    
    rails_obj[self.rails_field].each do |field|
      
    end
  end
end
