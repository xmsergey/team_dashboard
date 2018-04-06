class CreateTeamDashboardConfiguration < ActiveRecord::Migration
  def up
      create_table :team_dashboard_configurations do |t|
        t.text :configuration_name, null: false
        t.integer :user_id, null: false
        t.text :params, null: false

        t.timestamps
      end unless table_exists? :team_dashboard_configurations
  end

  def down
    drop_table :team_dashboard_configurations if table_exists? :team_dashboard_configurations
  end
end
