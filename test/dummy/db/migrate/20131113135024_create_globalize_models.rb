class CreateGlobalizeModels < ActiveRecord::Migration
  def change
    create_table :globalize_models do |t|
      t.string :string_field
      t.integer :integer_field

      t.timestamps
    end

    create_table :globalize_model_translations do |t|
      t.belongs_to :globalize_model, index: true

      t.string :title
      t.text :body

      t.string :locale
      t.timestamps
    end

    add_index :globalize_model_translations, :locale
  end
end
