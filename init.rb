require_dependency 'patches/team_dashboard_issue_patch'
require_dependency 'patches/team_dashboard_user_patch'

Redmine::Plugin.register :team_dashboard do
  name 'Team Dashboard plugin'
  author 'BelTech'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'https://redmine.plansource.com/plugins/team_dashboard'
  author_url ''

  permission :dashboard, { dashboard: [:index] }
  permission :team_management, { team_management: [:index, :update] }

  menu :project_menu, :dashboard, { controller: 'dashboard', action: 'index' }, caption: 'Team Dashboard', :after => :activity, :param => :project_id
  settings default: {}, partial: 'settings/params_settings'
end
