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
      else
        ids << create_erp_object(referenced_object, field.id)
      end
    end
    ids
  end
  
  def one2many_in_conversion(oerp_id)
    ext_object = self.external_object_referential.openerp_model    
    oerp_obj = eval(ext_object.classify).find(oerp_id)
    referenced_object = ExternalObjectReferential.find_by_rails_model(self.referenced_object)
    ids = []
    oerp_obj.send(self.openerp_field).each do |field|
      ext_id = referenced_object.extid_to_id(field.id)
      if ext_id
        ids << ext_id
      else
        ids << create_rails_object(referenced_object, field.id)
      end
    end    
  end
  
  #Convierte la id del objeto relacionado a openerp o lo crea en open
  def many2one_conversion(rails_id, related_id = nil)
    ext_object = self.external_object_referential.rails_model
    rails_obj = eval(ext_object).find(rails_id)
    referenced_object = ExternalObjectReferential.find_by_rails_model(self.referenced_object)
    id = nil
    if !related_id
      related_id = rails_obj.send(self.rails_field)
    end
    ext_id = referenced_object.id_to_extid(related_id)
    if ext_id
      id = ext_id
    else
      #Si no encuentra la id la creamos en openerp
      id = create_erp_object(referenced_object, related_id)
    end
    id
  end
  
  def many2one_in_conversion(oerp_id, related_id = nil)
    ext_object = self.external_object_referential.openerp_model
    oerp_obj = eval(ext_object.classify).find(oerp_id)
    referenced_object = ExternalObjectReferential.find_by_rails_model(self.referenced_object)
    id = nil
    if !related_id
      related_id = oerp_obj.send(self.openerp_field).id
    end
    ext_id = referenced_object.extid_to_id(related_id)
    if ext_id
      id = ext_id
    else
      id = create_rails_object(referenced_object, related_id)
    end
    id
  end
  
  def create_erp_object(referenced_object, rails_id)
    data = referenced_object.hash_to_erp(related_id)
    referenced_object.ext_export(data)
    #Ahora deberia estar creada la id de openerp
    id = referenced_object.id_to_extid(related_id)
    return id
  end
  
  def create_rails_object(referenced_object, oerp_id)
    if  referenced_object.import_function
      objects = eval(self.openerp_model.classify).find(:all)
      objects.each do |obj|        
        self.send(self.import_function, obj)
      end
      return true
    end
    data = referenced_object.hash_to_rails(oerp_id)
    referenced_object.ext_import(data)
    id = referenced_object.extid_to_id(oerp_id)
    return id
  end
end
