class ExternalObjectReferential < ActiveRecord::Base
  has_many :external_field_referentials, :dependent => :destroy
  
  def ext_export
    
    hash_to_erp.each do |item|
      #classify convierte product_product a ProductProduct
      obj = eval(self.openerp_model.classify).new(item)
      obj.save
    end
  end
  
  def internal_field_get(model, id, field)
      obj = eval(model).find(id)
      res = obj[field]
      res
  end
  
  def hash_to_erp()
    data = []    
    objects = eval(self.rails_model).find(:all, :limit => 10)
    objects.each do |obj|
      fields = {}
      self.external_field_referentials.each do |field|
        if field.col_type == 'string' || field.col_type == 'integer'
          fields[field.openerp_field.parameterize.underscore.to_sym] = obj[field.rails_field]
        elsif field.col_type == 'one2many'
          fields[field.openerp_field.parameterize.underscore.to_sym] = field.one2many_conversion(obj.id)
        end  
      end
      data << fields
    end
    data
  end
  
  def extid_to_id(ext_id)
    ref = ExternalReferential.find(:first, :conditions => ["rails_class = ? and openerp_id = ?", self.rails_model, ext_id])
    if ref
      return ref.rails_id
    end
    return false
  end
  
  def id_to_extid(id)
    ref = ExternalReferential.find(:first, :conditions => ["rails_class = ? and rails_id = ?", self.rails_model, id])
    if ref
      return ref.openerp_id
    end
    return false
  end
  

end
