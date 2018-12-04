require 'team_dashboard_constants'

class DashboardController < ApplicationController
  unloadable

  before_filter :find_project, only: %i[index edit_configuration new_configuration]
  before_filter :authorize, only: [:index]

  def index
    reset_session if request.get? && !params[:keep_session]
    save_to_session(params, request.post?)

    @technical_owner_field = CustomField.where(name: Setting.plugin_team_dashboard['technical_owner_field_name']).first
    @qa_owner_field = CustomField.where(name: Setting.plugin_team_dashboard['qa_owner_field_name']).first
    @pm_field = CustomField.where(name: TeamDashboardConstants::BELTECH_PM_FIELD_NAME).first
    @team_field = CustomField.where(name: Setting.plugin_team_dashboard['team_field_name']).first
    @external_priority_field = CustomField.where(name: TeamDashboardConstants::EXTERNAL_PRIORITY_FIELD_NAME).first

    @teams = TeamManagement.available_teams
    @selected_team = session_params(:team, @teams.keys.first)
    @selected_team_value = @teams[@selected_team]

    @versions = project_versions(@project)
    @selected_version_id = session_params(:target_version, current_version(@versions) && current_version(@versions).id)

    @ticket_status = 'open' if session_params(:ticket_status) == 'open'
    @show_support_tickets = params[:show_support_tickets] || session_params(:show_support_tickets)

    @show_ticket_different_teams = session_params(:show_ticket_different_teams, '1').to_i == 1

    @users = User.in_team(@selected_team_value).order([:firstname, :lastname])
    @configurations = TeamDashboardConfiguration.where(user_id: session[:user_id])

    @max_issues_count = @users.count > 0 ? @users.max_by { |user| user.overview_map_issues.count }.overview_map_issues.count : 0
  end

  def new_configuration
    @new_conf = true

    @teams = TeamManagement.available_teams
    @versions = ((@project.shared_versions.sort || []) + @project.rolled_up_versions.visible).uniq

    render 'edit_configuration'
  end

  def edit_configuration
    @new_conf = false
    @configuration = TeamDashboardConfiguration.find_by(id: params[:id])

    if TeamDashboardConfiguration.user_authorized?(@configuration, session[:user_id])
      @teams = TeamManagement.available_teams
      @versions = ((@project.shared_versions.sort || []) + @project.rolled_up_versions.visible).uniq
    else
      flash[:error] = l(:not_authorized_to_edit)
      redirect_to action: 'index'
    end
  end

  def load_configuration
    configuration = TeamDashboardConfiguration.find_by(id: params[:id])

    if TeamDashboardConfiguration.user_authorized?(configuration, session[:user_id])
      params[:keep_session] = true
      session[:team_dashboard_filter] ||= {}
      session[:team_dashboard_filter][:show_support_tickets] = false
      session[:team_dashboard_filter].merge!(configuration.params)
      flash[:notice] = l(:successfully_loaded)
    else
      flash[:error] = l(:not_authorized_to_load)
    end

    redirect_to action: 'index', keep_session: true
  end

  def save_configuration
    new_conf = params[:new_conf] == 'true'
    configuration = new_conf ? TeamDashboardConfiguration.new : TeamDashboardConfiguration.find_by(id: params[:configuration][:id])

    params[:configuration].delete(:id)
    params[:configuration][:user_id] = session[:user_id]

    if new_conf || TeamDashboardConfiguration.user_authorized?(configuration, session[:user_id])
      configuration_params[:params][:show_support_tickets] = true if configuration_params[:params][:show_support_tickets].present?
      configuration.update_attributes!(configuration_params)
      flash[:notice] = new_conf ? l(:successfully_created) : l(:successfully_updated)

      return redirect_to action: 'load_configuration', id: configuration.id if new_conf
    else
      flash[:error] = l(:not_authorized_to_update)
      return redirect_to action: 'index', keep_session: true
    end

    redirect_to action: 'index'
  end

  def remove_configuration
    configuration = TeamDashboardConfiguration.find_by(id: params[:id])

    if TeamDashboardConfiguration.user_authorized?(configuration, session[:user_id])
      configuration.destroy
      configurations = TeamDashboardConfiguration.user_configurations(session[:user_id])
      flash[:notice] = l(:successfully_removed)

      return redirect_to action: 'load_configuration', id: configurations.first.id if configurations.size == 1
    else
      flash[:error] = l(:not_authorized_to_remove)
    end

    redirect_to action: 'index'
  end

  private

  def find_project
    # @project variable must be set before calling the authorize filter
    @project = Project.find(params[:project_id])
  end

  def project_versions(project)
    ((project.shared_versions.sort || []) + project.rolled_up_versions.visible).delete_if do |version|
      version.closed? || version.completed?
    end.uniq
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

  def configuration_params
    params.require(:configuration).permit(:configuration_name, :user_id).tap do |whitelisted|
      whitelisted[:params] = params[:configuration][:params]
    end
  end

  def current_version(versions)
    dates = {}
    versions.select do |version|
      version_date = version.name.match('\d+(-|\/)\d+(-|\/)\d+').to_s.gsub('-','/')
      next if version_date.blank?

      date = Date.strptime(version_date, '%Y/%m/%d') rescue nil || Date.strptime(version_date, '%m/%d/%Y') rescue nil
      dates[date] = version if date && (date >= Date.today)
    end
    dates.sort.first && dates.sort.first[1]
  end

end
