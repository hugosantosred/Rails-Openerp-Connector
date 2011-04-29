class ExternalFieldReferential < ActiveRecord::Base
  belongs_to :external_object_referential  
  
  #Convierte campos uno a muchos de rails a ids de openerp
  def one2many_conversion(rails_id)
    ext_object = self.external_object_referential.rails_model
    rails_obj = eval(ext_object).find(rails_id)
    referenced_object = ExternalObjectReferential.find_by_rails_model(self.referenced_object)
    ids = []
    puts ext_object
    puts rails_id
    puts self.rails_field
    #.send llama al metodo o campo pasado como parametro para ese objeto
    rails_obj.send(self.rails_field).each do |field|
      ext_id = referenced_object.id_to_extid(field.id)
      if ext_id
        ids << ext_id
      end
    end
    ids
  end
  
  
end
