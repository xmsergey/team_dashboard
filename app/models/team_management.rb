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
    team_field = CustomField.where(name: TeamDashboardConstants::TEAM_FIELD_NAME).first
    teams = team_field.present? ? team_field.possible_values_options : []

    ret_val = {}
    teams.each { |team| ret_val[team.parameterize] = team }
    ret_val
  end

  def self.teamed_users
    self.all.collect { |team| team.user }
  end

  def self.non_teamed_users
    User.sorted.where(type: TeamDashboardConstants::USER_TYPE_NAME).to_a - self.teamed_users
  end

  def self.team(name)
    self.where(team_name: name)
  end

  def qa_members
    team(TeamDashboardConstants::QA_TEAM_NAMES)
  end
end