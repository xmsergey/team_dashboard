class CreateTeamManagement < ActiveRecord::Migration
  def up
      create_table :team_managements do |t|
        t.text :team_name, null: false
        t.integer :user_id, null: false

        t.timestamps
      end unless table_exists? :team_managements
  end

  def down
    drop_table :team_managements if table_exists? :team_managements
  end
end
