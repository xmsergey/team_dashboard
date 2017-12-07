class SetDefaultPluginSettingValues < ActiveRecord::Migration
  PLUGIN_NAME = 'plugin_team_dashboard'.freeze

  def up
    settings = Setting.find_or_initialize_by(name: PLUGIN_NAME)
    settings.value = ActionController::Parameters.new({
      team_field_name: 'Team',
      technical_owner_field_name: 'Technical Owner',
      qa_owner_field_name: 'QA Owner'
    })
    settings.save!
  end

  def down
    Setting.find_by(name: PLUGIN_NAME)&.destroy
  end
end
