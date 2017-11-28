require_dependency 'issue'

module TeamDashboard
  module IssuePatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)
    end

    module InstanceMethods
      def technical_owner_value
        value = technical_owner_field.custom_field.cast_value(technical_owner_field.value).to_s if technical_owner_field.present?
        yield value if block_given?
        value
      end

      def technical_owner_field
        issue_value_by_field_name(TeamDashboardConstants::TECHNICAL_OWNER_FIELD_NAME)
      end

      def qa_specialist_value
        value = qa_specialist_field.custom_field.cast_value(qa_specialist_field.value).to_s if qa_specialist_field.present?
        yield value if block_given?
        value
      end

      def qa_specialist_field
        issue_value_by_field_name(TeamDashboardConstants::QA_SPECIALIST_FIELD_NAME)
      end

      def remaining_hours
        ret_val = nil
        custom_field_value = issue_value_by_field_name(TeamDashboardConstants::REMAINING_TIME_FIELD_NAME)
        ret_val = custom_field_value.value.to_f if custom_field_value && custom_field_value.value
        ret_val
      end

      def is_shared_with?(user)
        user.user_events.shared_tasks.any? { |shared_task| shared_task.issue == self }
      end

      private

      def issue_value_by_field_name(name)
        custom_field_values.detect { |cfv| cfv.custom_field.name.casecmp(name).zero? }
      end
    end
  end
end

# Add module to User
Issue.send(:include, TeamDashboard::IssuePatch)