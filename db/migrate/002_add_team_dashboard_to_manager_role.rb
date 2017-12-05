class AddTeamDashboardToManagerRole < ActiveRecord::Migration
  def up
    role = Role.find_by(name: 'Manager')
    return unless role

    role.add_permission!(:dashboard, :team_management)
  end

  def down
    role = Role.find_by(name: 'Manager')
    return unless role

    role.remove_permission!(:dashboard, :team_management)
  end
end
