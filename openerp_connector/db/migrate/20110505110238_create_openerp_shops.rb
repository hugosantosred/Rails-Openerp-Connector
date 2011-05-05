class CreateOpenerpShops < ActiveRecord::Migration
  def self.up
    create_table :openerp_shops do |t|
      t.string :shop_name      
    end
  end

  def self.down
    drop_table :openerp_shops
  end
end
