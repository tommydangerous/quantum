class CreateNotes < ActiveRecord::Migration
  def change
    create_table :notes do |t|
      t.text :body
      t.boolean :completed

      t.timestamps
    end
  end
end
