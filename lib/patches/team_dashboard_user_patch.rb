require_dependency 'user'

module TeamDashboard
  module UserPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        has_many :user_events

        scope :in_team, lambda {|team_name|
          where("#{User.table_name}.id IN (SELECT tm.user_id FROM #{table_name_prefix}team_managements#{table_name_suffix} tm WHERE tm.team_name IN (?))", team_name)
        }
      end
    end

    module InstanceMethods

      def is_qa_member?(qa_owner_field)
        values = qa_owner_field && qa_owner_field.possible_values
        values && values.detect { |value| value.include?(self.name) }.present?
      end

      def estimated_hours(type = :total)
        issue_relation = issues
        hours = 0

        if type != :total
          issue_relation = issue_relation.joins('join enumerations e on e.id = issues.priority_id')
                             .where("e.position_name #{type == :background ? '=' : '<>'} 'lowest'")
        end

        issue_relation.each do |local_issue|
          rough_est_custom_field = CustomField.where(name: TeamDashboardConstants::REMAINING_TIME_FIELD_NAME).first
          if rough_est_custom_field
            est = local_issue.custom_field_value(rough_est_custom_field).to_i
            hours += est
          end
        end

        hours
      end

      def issues
        Issue.joins('join issue_statuses iss on iss.id = issues.status_id')
            .where(assigned_to_id: self.id)
            .order('priority_id desc, id asc')
      end

      def shared_issues
        self.user_events.current_shared_tasks.map(&:issue).sort_by { |issue| issue.priority.id }.reverse
      end

      def overview_map_issues
        (self.issues + self.shared_issues).sort_by(&:id)
      end

      def assigned_issues
        self.issues + self.shared_issues
      end

      def photo_file_name(assets_path = '')
        path = "#{self.firstname}_#{self.lastname}".downcase

        TeamDashboardConstants::ALLOWED_IMAGE_EXTENSIONS.each do |ext|
          if File.exist?("#{assets_path}/images/avatars/#{path + ext}")
            path += ext
            break
          end
        end

        path
      end

      def today_report
        @today_report ||= UserReport.today.where(user_id: self.id).first
      end
    end
  end
end

# Add module to User
User.send(:include, TeamDashboard::UserPatch)
