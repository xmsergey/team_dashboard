module DashboardHelper

  def get_avatar(user)
    path_to_avatar = "plugins/team-dashboard/assets/images/#{avatar_path(user)}"
    if File.exist?(path_to_avatar)
      avatar_path(user)
    else
      'avatars/default.png'
    end
  end

  def avatar_path(user)
    "avatars/#{user.photo_file_name}"
  end

  def eta_value(issue)
    remaining_hours = issue.remaining_hours

    ret_val = '--'
    ret_val = "#{remaining_hours.to_i}" + content_tag(:small, 'h') if remaining_hours && remaining_hours > 0
    ret_val.html_safe
  end

  def owner_value_short(user, issue)
    name = owner_value(user, issue).to_s.split(' ')

    ret_val = '--'
    ret_val = "#{name[0].first}#{name[1].first}" if name.length >= 2
    ret_val.html_safe
  end

  def owner_value(user, issue)
    user.is_qa_member? ? issue.qa_specialist_value : issue.technical_owner_value
  end

  def priority_class(issue)
    "priority #{issue.priority.name.downcase}-priority"
  end

  def module_class
    return 'module' if @max_issues_count < TeamDashboardConstants::ISSUES_PER_CARD
    @max_issues_count == TeamDashboardConstants::ISSUES_PER_CARD ? 'module module-4' : 'module module-more'
  end

  def view_all_issues_path(user)
    params = []
    params << 'c[]=project&c[]=tracker&c[]=status&c[]=priority&c[]=subject&c[]=assigned_to&c[]=updated_on'
    params << 'f[]=status_id&f[]=assigned_to_id&f[]=&group_by='
    params << 'op[assigned_to_id]==&op[status_id]=o&set_filter=1'
    params << 'sort=priority:desc,id:asc'
    params << "utf8=✓&v[assigned_to_id][]=#{user.id}"
    URI.escape("/issues?#{params.join('&')}")
  end

  def issue_id_and_subject_tag(user, issue, display_shared_mark, display_initials)
    hint = css = link_css = ''

    options = {}
    options = options.merge(class: css.strip) unless css.blank?
    options = options.merge(title: hint.strip) unless hint.blank?

    ret_val = ''
    ret_val << content_tag(:span, 'S-', options) if display_shared_mark && issue.is_shared_with?(user)
    ret_val << content_tag(:span, issue.id, options)
    ret_val << "\n"
    ret_val << link_to(issue.subject, issue_path(issue), title: issue.subject, class: link_css)
    ret_val.html_safe
  end

  def version_options_for_select(versions, selected_version_id=nil, show_completed = false)
    completed_versions = versions.select {|version| version.closed? || version.completed? }
    worked_versions = versions - completed_versions

    selected_version_id = worked_versions.first.try(:id) || completed_versions.first.try(:id) unless selected_version_id

    if show_completed && completed_versions
      grouped = [
        ['', worked_versions.collect {|version| [version.name, version.id]}],
        ['Completed Versions', completed_versions.collect {|version| [version.name, version.id]}]
      ]
      grouped_options_for_select(grouped, selected_version_id)
    else
      options_from_collection_for_select(worked_versions, :id, :name, selected_version_id)
    end
  end

  def user_issues(user)
    owner_field = user.is_qa_member? ? @qa_owner_field : @technical_owner_field

    value = owner_field.field_format == 'user' ? user.id : user.name
    Issue.visible
      .joins("INNER JOIN custom_values cf ON cf.customized_id = issues.id AND customized_type = 'Issue' and custom_field_id = #{owner_field.id} AND value = '#{value}'")
      .where(fixed_version_id: @selected_version_id)
  end

end
