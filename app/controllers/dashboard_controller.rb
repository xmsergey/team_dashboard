require 'team_dashboard_constants'

class DashboardController < ApplicationController
  unloadable

  before_filter :find_project, :authorize, only: [:index]

  def index
    reset_session if request.get?
    save_to_session(params, request.post?)

    @technical_owner_field = CustomField.where(name: TeamDashboardConstants::TECHNICAL_OWNER_FIELD_NAME).first
    @qa_owner_field = CustomField.where(name: TeamDashboardConstants::QA_SPECIALIST_FIELD_NAME).first

    @teams = TeamManagement.available_teams
    @selected_team = session_params(:team, @teams.keys.first)

    @versions = ((@project.shared_versions.sort || []) + @project.rolled_up_versions.visible).uniq
    @selected_version_id = session_params(:target_version).present? ? session_params(:target_version).to_i : nil

    @users = User.in_team(@teams[@selected_team]).order([:firstname, :lastname])

    @max_issues_count = @users.count > 0 ? @users.max_by { |user| user.overview_map_issues.count }.overview_map_issues.count : 0
  end

  def upload_image
    user = User.find_by_id(params[:id])
    image = params[:file].try(:tempfile)
    return unless image

    path = "#{get_dir_plugin_assets}/images/#{get_avatar_path(user)}"
    path_assets_redmine = "#{get_dir_public_assets}/images/#{get_avatar_path(user)}"

    File.open(path, 'wb') do |f|
      f.write(image.read)
    end
    image.rewind
    image.read

    FileUtils.cp(path, path_assets_redmine)

    redirect_to action: :index
  end

  def remove_image
    user = User.find_by_id(params[:user_id])

    path = "#{get_dir_plugin_assets}/images/#{get_avatar_path(user)}"
    path_assets_redmine = "#{get_dir_public_assets}/images/#{get_avatar_path(user)}"
    return render json: {error_messages: 'File exist' } unless File.exist? path

    File.delete(path)
    File.delete(path_assets_redmine)

    redirect_to action: :index
  end

  private

  def get_dir_plugin_assets
    Redmine::Plugin.find(TeamDashboardConstants::PLUGIN_NAME).assets_directory
  end

  def get_dir_public_assets
    Redmine::Plugin.find(TeamDashboardConstants::PLUGIN_NAME).public_directory
  end

  def get_avatar_path(user)
    "avatars/#{"#{user.firstname}_#{user.lastname}.jpg".downcase}"
  end

  def find_project
    # @project variable must be set before calling the authorize filter
    @project = Project.find(params[:project_id])
  end

  def save_to_session(params_filter, force = false)
    session[:team_dashboard_filter] = params_filter if session && (force || !session[:team_dashboard_filter])
  end

  def reset_session
    session[:team_dashboard_filter] = nil
  end

  def session_params(name, default = nil)
    session.try(:[], :team_dashboard_filter).try(:[], name) || default
  end
end
