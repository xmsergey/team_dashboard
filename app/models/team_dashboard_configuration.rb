class TeamDashboardConfiguration < ActiveRecord::Base
  unloadable

  belongs_to :user

  serialize :params

  validates_presence_of :configuration_name, maximum: 80
  validates_presence_of :user_id
  validates_presence_of :params

  def self.user_authorized?(configuration, user_id)
    return false unless configuration

    configuration.user_id == user_id
  end

  def self.user_configurations(user_id)
    TeamDashboardConfiguration.where(user_id: user_id)
  end
end
