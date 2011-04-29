class CreateExternalFieldReferentials < ActiveRecord::Migration
  def self.up
    create_table :external_field_referentials do |t|
      t.references :external_object_referential
      t.string :openerp_field
      t.string :rails_field
      t.string :col_type
      t.string :referenced_object
    end
  end

  def self.down
    drop_table :external_field_referentials
  end
end
