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
      conditions = []
      if self.erp_import_conditions
        conditions << eval(self.erp_import_conditions)
      end
      if conditions.empty?
        objects = eval(self.openerp_model.classify).find(:all)
      else
        objects = eval(self.openerp_model.classify).find(:all, :domain => conditions)
      end
      objects.each do |obj|        
        self.send(self.import_function, obj)
      end
      return true
    end
    
    if !data
      data = hash_to_rails
    end
    puts "DATA: #{data}"
    data.each do |item|
      #begin
      obj = eval(self.rails_model).new(item[0])
      if obj.save
        int_ref = ExternalReferentialId.new(:openerp_id => item[1], :rails_id => obj.id, :rails_class => self.rails_model)
        int_ref.save
      else
        logger.info("Error: #{item[0]} no puede guardarse")
      end
        #rescue        
        #puts "ERROR: #{self.rails_model} #{item[0]}"
        #end
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
        if field.col_type == 'string' || field.col_type == 'number'
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
    #Añadimos a las condiciones las definidas en el objeto (Para importar los productos padres solamente por ejemplo)
    if self.erp_import_conditions
      conditions << eval(self.erp_import_conditions)
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
        if field.col_type == 'string' || field.col_type == 'number'
          fields[field.rails_field.parameterize.underscore.to_sym] = obj.send(field.openerp_field)
        elsif field.col_type == 'one2many'
          fields[field.rails_field.parameterize.underscore.to_sym] = field.one2many_in_conversion(obj.id)
        elsif field.col_type == 'many2one'
          fields[field.rails_field.parameterize.underscore.to_sym] = obj.send(field.openerp_field) && field.many2one_in_conversion(obj.id)        
        end        
      end
      puts "Campos hash to rails: #{fields}"
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
            ext_taxonomy = ExternalReferentialId.new(:rails_class => "Taxonomy", :openerp_id => category.id, :rails_id => taxonomy.id)
            ext_taxonomy.save
          end
          taxonomy_id = taxonomy.id
          categ = taxonomy.taxons[0]
        end
        ex_id = ExternalReferentialId.new(:openerp_id => category.id, :rails_id => categ.id, :rails_class => "Taxon")
        ex_id.save
    end
    puts "Categoría: #{categ.name} #{categ.permalink}"
    return categ      
  end

#ADDITIONAL FUNCTIONS
    def find_or_create_template(template)
      if !Prototype.find_by_name(template.name)
        proto = Prototype.new(:name => template.name)
        proto.save
        template.features.each do |feat|
          prop = find_or_create_property(feat)
          prop.prototypes = prop.prototypes + [proto]
          prop.save
        end
      end      
    end
  
    def find_or_create_property(property)
      prop = Property.find_or_create_by_name(:name => property.name, 
                                    :presentation => property.presentation)
      return prop
    end
  
    def add_features(product_id, property, value)
      prop = find_or_create_property(property)
      prodProp = ProductProperty.new(:product_id => product_id,
                            :property_id => prop.id,
                            :value => value)
      prodProp.save
    end



  def find_or_create_product(prod)
    

    rails_ref = ExternalReferentialId.find(:first, :conditions => ['rails_class = ? and openerp_id = ?', 'Product', prod.id])
    #Si ese producto no existe lo crearemos
    
    
    if !rails_ref
      puts "Nuevo Producto #{prod.name} Categoria: #{prod.categ_id.name}"
      
      if prod.dimension_value_ids.empty? && prod.is_master==true
        
        product = Product.new(:name => prod.name, :price => prod.list_price, :description => prod.description || '',
                              :cost_price => prod.standard_price, :available_on => Date.today.to_s)
        
        category = find_or_create_category(prod.categ_id)
        product.taxons << category
        
        if prod.categ_ids != false
          prod.categ_ids.each do |categ|
            category = find_or_create_category(categ)
            product.taxons << category
          end
        end
        
        product.sku = prod.default_code || ''        
        #product.save
        
        if prod.variant_ids != false
          templ = prod.product_tmpl_id
          if templ.dimension_type_ids != false
            templ.dimension_type_ids.each do |opt|
              option_type = OptionType.find_or_create_by_name(:name => opt.name.parameterize('_').to_s, :presentation => opt.name)
              opt.value_ids.each do |val|
                optVal = OptionValue.find_or_create_by_option_type_id_and_name(:option_type_id => option_type.id,
                                        :name => val.name.parameterize('_').to_s, :presentation => val.name,
                                        :position => val.sequence)
              end
              product.option_types << option_type
            end
          end
          product.save
                                       
          prod.variant_ids.each do |variant|
            variant_ext = ExternalReferentialId.find(:first, :conditions => ['rails_class = ? and openerp_id = ?', 'Variant', variant.id])
            if !variant_ext
              if variant.id != prod.id
                var = Variant.new(:product_id => product.id, :sku => variant.default_code || '',
                          :price => variant.list_price, :cost_price => variant.standard_price)
                if variant.dimension_value_ids != false
                  variant.dimension_value_ids.each do |opt|
                    option_type = OptionType.find_by_name(opt.dimension_id.name.parameterize('_').to_s)
                    optVal = OptionValue.find_by_option_type_id_and_name(option_type.id,
                                                                opt.name.parameterize('_').to_s)
                    var.option_values << optVal
                  end
                end
                var.save
                variant_ext = ExternalReferentialId.create(:rails_class => "Variant", :openerp_id => variant.id, :rails_id => var.id)
                variant_ext.save              
              end
            end
          end
        end
        
        if prod.feature_template
          find_or_create_template(prod.feature_template)
        end
        
        if prod.features
          prod.features.each do |feat|
            add_features(product.id, feat.name, feat.value)
          end
        end
        product.save
        rails_ref = ExternalReferentialId.create(:rails_class => "Product", :openerp_id => prod.id, :rails_id => product.id)
        rails_ref.save        
      end
    end

  end
  
  def extid_to_id(ext_id, r_model = nil)
    if !r_model
      r_model = self.rails_model
    end
    ref = ExternalReferentialId.find(:first, :conditions => ["rails_class = ? and openerp_id = ?", r_model, ext_id])
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
