class CreateExternalObjectReferentials < ActiveRecord::Migration
  def self.up
    create_table :external_object_referentials do |t|
      t.column :openerp_model, :string
      t.column :rails_model, :string      
    end
  end

  def self.down
    drop_table :external_object_referentials
  end
end
