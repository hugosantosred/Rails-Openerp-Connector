class CreateExternalReferentials < ActiveRecord::Migration
  def self.up
    create_table :external_referentials do |t|
      t.column :openerp_id, :integer
      t.column :rails_id, :integer
      t.column :rails_class, :string
    end
  end

  def self.down
    drop_table :external_referentials
  end
end
