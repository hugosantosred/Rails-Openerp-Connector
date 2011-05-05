class OpenerpShop < ActiveRecord::Base
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
end
