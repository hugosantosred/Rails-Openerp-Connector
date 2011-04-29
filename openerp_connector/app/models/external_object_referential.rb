class ExternalObjectReferential < ActiveRecord::Base
  has_many :external_field_referentials, :dependent => :destroy
  
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
        if field.type == 'string' || field.type == 'integer'
          fields[field.openerp_field.parameterize.underscore.to_sym] = obj[field.rails_field]
        elsif field.type == 'one2many'
          fields[field.openerp_field.parameterize.underscore.to_sym] = field.one2many_conversion(obj.id)
        end  
      end
      data << fields
    end
    data
  end
end
