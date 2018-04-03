class TeamManagement < ActiveRecord::Base
  unloadable

  belongs_to :user

  validates_presence_of :team_name
  validates_presence_of :user_id

  def self.team_members
    ret_val = {}
    self.all.each do |assignment|
      team_key = assignment.team_name.parameterize
      ret_val[team_key] ||= []
      ret_val[team_key] << assignment.user
    end
    ret_val
  end

  def self.available_teams
    team_field = CustomField.where(name: Setting.plugin_team_dashboard['team_field_name']).first
    teams = team_field.present? ? team_field.possible_values_options : []

    ret_val = {}
    teams.each { |team| ret_val[team.parameterize] = team }
    ret_val
  end

  def self.all_users
    User.sorted.where(type: TeamDashboardConstants::USER_TYPE_NAME).to_a
  end

  def self.teamed_users
    self.all.collect { |team| team.user }
  end

  def self.non_teamed_users
    self.all_users - self.teamed_users
  end

  def self.team(name)
    self.where(team_name: name)
  end
end
