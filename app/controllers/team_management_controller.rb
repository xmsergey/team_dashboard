require 'team_dashboard_constants'

class TeamManagementController < ApplicationController

  before_filter :find_project, :initialize_for_layout, :authorize, only: [:index, :update]


  def initialize_for_layout
    @teams_available = TeamManagement.available_teams
  end

  def index
    team_members = TeamManagement.team_members
    @teams = {}
    @teams_available.each_key { |team_key| @teams[team_key] = team_members[team_key] || [] }
    @unselected_users = TeamManagement.all_users
  end

  def update
    TeamManagement.delete_all

    option_keys = params.keys.select { |pm| pm['team_'] }
    option_keys.each do |param|
      team = params[param]
      team.each do |user|
        team_name = @teams_available[param[5..-1]]
        user_id = user.to_i
        TeamManagement.create!(team_name: team_name, user_id: user_id) if user_id.to_i > 0 && team_name.present?
      end if team.is_a?(Array) && team.any?
    end

    flash[:notice] = 'Groups updated successfully.'
    redirect_to_referer_or action: 'index', project_id: params[:project_id]
  end

  private

  def find_project
    # @project variable must be set before calling the authorize filter
    @project = Project.find(params[:project_id])
  end
end