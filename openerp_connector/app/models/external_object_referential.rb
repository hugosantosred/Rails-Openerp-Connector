class ExternalObjectReferential < ActiveRecord::Base
  has_many :external_field_referentials, :dependent => :destroy
  
  def ext_export(data = nil)    
    if !data
      data = hash_to_erp
    end
    data.each do |item|
      #classify convierte product_product a ProductProduct
      obj = eval(self.openerp_model.classify).new(item[0])
      obj.save
      ext_ref = ExternalReferentialId.new(:openerp_id => obj.id, :rails_class => self.rails_model, :rails_id => item[1])
      ext_ref.save
    end
  end
  
  def ext_import(data = nil)
    #Si tiene funcion de importacion la llamamos en lugar de a la conversion
    if self.import_function
      objects = eval(self.openerp_model.classify).find(:all)
      objects.each do |obj|        
        self.send(self.import_function, obj)
      end
      return true
    end
    
    if !data
      data = hash_to_rails
    end
    data.each do |item|
      obj = eval(self.rails_model).new(item[0])
      if obj.save
        int_ref = ExternalReferentialId.new(:openerp_id => item[1], :rails_id => obj.id, :rails_class => self.rails_model)
        int_ref.save
      end
    end
  end
  
  def internal_field_get(model, id, field)
      obj = eval(model).find(id)
      res = obj[field]
      res
  end
  
  #Convert Rails model to openerp_hash based in externalFieldsReferential Defined
  def hash_to_erp(id = nil)
    data = []
    #Search for already created objects for this rails_model
    external_ids = ExternalReferentialId.find(:all, :conditions => ["rails_class = ?", self.rails_model])
    created_ids = external_ids && external_ids.map{|ex| ex.rails_id} || []
    conditions = []
    if !created_ids.empty?
      conditions = ['id not in (?)', created_ids]
    end
    if id
      objects = [eval(self.rails_model).find(id)]
    else
      objects = eval(self.rails_model).find(:all, :conditions => conditions)
    end
    objects.each do |obj|
      fields = {}
      self.external_field_referentials.each do |field|
        if field.col_type == 'string' || field.col_type == 'integer'
          fields[field.openerp_field.parameterize.underscore.to_sym] = obj[field.rails_field]
        elsif field.col_type == 'one2many'
          fields[field.openerp_field.parameterize.underscore.to_sym] = field.one2many_conversion(obj.id)
        elsif field.col_type == 'many2one'
          oerp_id = false
          rails_val = obj.send(field.rails_field)
          if rails_val
            if rails_val.class == Array
              related_id = !rails_val.empty? && rails_val.first
              oerp_id = related_id && field.many2one_conversion(obj.id, related_id)
            else
              oerp_id = field.many2one_conversion(obj.id)
            end
          end
          fields[field.openerp_field.parameterize.underscore.to_sym] = oerp_id
        end  
      end
      data << [fields, obj.id]
    end
    data
  end
  
  def hash_to_rails(id=nil)
    data = []
    external_ids = ExternalReferentialId.find(:all, :conditions => ["rails_class = ?", self.rails_model])
    created_ids = external_ids && external_ids.map{|ex| ex.openerp_id} || []
    conditions = []
    #Condicion en formato dominio openerp
    if !created_ids.empty?
      conditions = [['id','not in',created_ids]]
    end
    if id
      objects = [eval(self.openerp_model.classify).find(id)]
    else
      objects = eval(self.openerp_model.classify).find(:all, :domain => conditions)
    end
    
    #Convertir objetos obtenidos de openerp a objetos rails
    objects.each do |obj|
      fields = {}
      self.external_field_referentials.each do |field|
        if field.col_type == 'string' || field.col_type == 'integer'
          fields[field.rails_field.parameterize.underscore.to_sym] = obj.send(field.openerp_field)
        elsif field.col_type == 'one2many'
          fields[field.rails_field.parameterize.underscore.to_sym] = field.one2many_in_conversion(obj.id)
        elsif field.col_type == 'many2one'
          fields[field.rails_field.parameterize.underscore.to_sym] = obj.send(field.openerp_field) && field.many2one_in_conversion(obj.id)        
        end
        puts fields
      end
      data << [fields, obj.id]      
    end
    return data
  end
  
  def create_taxonomies
    objects = ProductProduct.find(:all, :conditions => [['parent_id','=',false]])    
    objects.each do |obj|
      ext_id = ExternalReferentialId.find(:first, :conditions => ['rails_class = ? and openerp_id = ?', "Taxonomy", obj.id])
      if !ext_id
        tax = Taxonomy.new(:name => obj.name)
        tax.save
        ext_id = ExternalReferentialId.new(:rails_class => "Taxonomy", :openerp_id => obj.id, :rails_id => tax.id)
        ext_id.save
      end
    end    
  end
  
  def find_or_create_category(category)
    
    ext_id = ExternalReferentialId.find(:first, :conditions => ['rails_class = ? and openerp_id = ?', "Taxon", category.id])
    categ = nil
    if ext_id
      begin
        categ = Taxon.find(ext_id.rails_id)
      end
    end
    if not categ
      if category.parent_id
          parent_taxon = find_or_create_category(category.parent_id)
          #taxonomy_id = Taxonomy.find             
          parent_id =  parent_taxon.id
          taxonomy = Taxonomy.find(parent_taxon.taxonomy.id)
          categ = taxonomy.taxons.create(:name => category.name, :parent_id => parent_id)
        else
          parent_id = nil
          ext_taxonomy = ExternalReferentialId.find(:first, :conditions => ['rails_class = ? and openerp_id = ?', "Taxonomy", category.id])
          if ext_taxonomy
            taxonomy = Taxonomy.find(ext_taxonomy.rails_id)
            ext_taxonomy = ExternalReferentialId.find(:first, :conditions => ['rails_class = ? and openerp_id = ?', "Taxonomy", category.id])
            ext_taxonomy.save
          else
            taxonomy = Taxonomy.new(:name => category.name)
            taxonomy.save
          end
          taxonomy_id = taxonomy.id
          categ = taxonomy.taxons[0]
        end
        ex_id = ExternalReferentialId.new(:openerp_id => category.id, :rails_id => categ.id, :rails_class => self.rails_model)
        ex_id.save
    end
    return categ      
  end
  
  def extid_to_id(ext_id)
    ref = ExternalReferentialId.find(:first, :conditions => ["rails_class = ? and openerp_id = ?", self.rails_model, ext_id])
    if ref
      return eval(ref.rails_class).find(ref.rails_id) #retornamos el objecto rails
    end
    return false
  end
  
  def id_to_extid(id)
    ref = ExternalReferentialId.find(:first, :conditions => ["rails_class = ? and rails_id = ?", self.rails_model, id])
    if ref
      return ref.openerp_id
    end
    return nil
  end
  

end
