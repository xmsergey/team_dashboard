module DashboardHelper

  def get_avatar(user)
    plugin = Redmine::Plugin.find(TeamDashboardConstants::PLUGIN_NAME) rescue nil
    return nil unless plugin

    path_to_avatar = "#{File.join(plugin.assets_directory, 'images/')}#{avatar_path(user, plugin.assets_directory)}"

    if File.exist?(path_to_avatar)
      avatar_path(user, plugin.assets_directory)
    else
      'avatars/default.png'
    end
  end

  def avatar_path(user, assets_path)
    "avatars/#{user.photo_file_name(assets_path)}"
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
    user.is_qa_member?(@qa_owner_field) ? issue.qa_specialist_value : issue.technical_owner_value
  end

  def priority_class(issue)
    "priority #{issue.priority.name.downcase}-priority"
  end

  def module_class
    issues_in_card = TeamDashboardConstants::ISSUES_PER_CARD
    issues_in_card_six = TeamDashboardConstants::ISSUES_PER_CARD_6

    return 'module' if @max_issues_count < issues_in_card
    (@max_issues_count >= issues_in_card && @max_issues_count < issues_in_card_six) ? 'module module-6' : 'module module-more'
  end

  def view_all_issues_path(user)
    owner_field = owner_instance(user)
    search_params = owner_field.eql?(@qa_owner_field) ? user.name.gsub(' ', '+') : user.id
    target_version = @selected_version_id ? "=&v[fixed_version_id][]=#{@selected_version_id}" : '*'

    params = []
    params << 'set_filter=1&sort=priority:desc,id&group_by=&t[]='
    params << "c[]=project&c[]=tracker&c[]=status&c[]=priority&c[]=subject&c[]=assigned_to&c[]=updated_on"
    params << "c[]=cf_#{owner_field.id}&c[]=fixed_version"
    params << "op[status_id]=*&op[cf_#{owner_field.id}]==&op[fixed_version_id]=#{target_version}"
    params << "f[]=status_id&f[]=cf_#{owner_field.id}&f[]=fixed_version_id&f[]="
    params << "utf8=✓&v[cf_#{owner_field.id}][]=#{search_params}"
    URI.escape("/projects/plansource/issues?#{params.join('&')}")
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
    owner_field = owner_instance(user)
    value = owner_field.field_format == 'user' ? user.id : user.name

    issues =
      Issue.select('issues.*, ad.story_points, cv.value AS `external_priority`').visible
        .joins("INNER JOIN custom_values cf ON cf.customized_id = issues.id AND customized_type = 'Issue'")
        .joins("JOIN custom_fields cuf ON cuf.name = '#{TeamDashboardConstants::EXTERNAL_PRIORITY_FIELD_NAME}'")
        .joins('LEFT JOIN custom_values cv ON cv.customized_id = issues.id AND cv.custom_field_id = cuf.id')
        .joins('LEFT JOIN agile_data ad ON ad.issue_id = issues.id')
        .where(fixed_version_id: @selected_version_id)
        .where(cf: { custom_field_id: owner_field.id, value: value })

    @ticket_status ? issues.open : issues
  end

  def support_issues
    all_issues =
      Issue.select('cv1.value as esc_tier_3_time, cv2.value as support_analyst, issues.*')
        .joins('join issue_statuses iss_st on iss_st.id = issues.status_id and iss_st.is_closed != 1')
        .joins("join custom_values cv1 on cv1.customized_id = issues.id and cv1.customized_type = 'Issue'")
        .joins("join custom_fields cf1 on cf1.id = cv1.custom_field_id and cf1.name = '#{TeamDashboardConstants::TIER_3_ESC_DATE_FIELD_NAME}'")
        .joins("join custom_values cv2 on cv2.customized_id = issues.id and cv2.customized_type = 'Issue'")
        .joins("join custom_fields cf2 on cf2.id = cv2.custom_field_id and cf2.name = '#{TeamDashboardConstants::SUPPORT_ANALYST_FIELD_NAME}'")
        .joins("join custom_values cv3 on cv3.customized_id = issues.id and cv3.customized_type = 'Issue'")
        .joins("join custom_fields cf3 on cf3.id = cv3.custom_field_id and cf3.name = '#{TeamDashboardConstants::TIER_3_TEAM_FIELD_NAME}'")
        .where("cv1.value != '' and cv3.value = ?", @teams[@selected_team])

    issues = {}
    selected_issue_ids = []

    TeamDashboardConstants::SUPPORT_TICKET_GROUPS.each do |group_code, _|
      case group_code
      when :support_team then
        issues[group_code] =
          all_issues
            .select("CONCAT(u.firstname, ' ', u.lastname) as assigned_to")
            .joins('JOIN users u on u.id = issues.assigned_to_id')
            .where("cv2.value != ''")
            .having("INSTR((select cf.possible_values from custom_fields cf
                    where cf.name = 'Support Analyst'), assigned_to)")
        selected_issue_ids.push(issues[group_code].map(&:id)).flatten!
      when :ps_developer then
        issues[group_code] =
          all_issues
            .joins('join users u on u.id = issues.assigned_to_id')
            .joins('join members m on m.user_id = u.id')
            .joins('join member_roles mr on mr.member_id = m.id')
            .joins('join roles r on r.id = mr.role_id')
            .where("r.name = '#{TeamDashboardConstants::PS_DEVELOPER_ROLE_NAME}' || r.name = '#{TeamDashboardConstants::PS_DEVELOPER_QA_ROLE_NAME}'")
            .group('issues.id')
        selected_issue_ids.push(issues[group_code].map(&:id)).flatten!
      when :beltech then
        issues[group_code] =
          all_issues
            .joins("join custom_values cv4 on cv4.customized_id = issues.id and cv4.customized_type = 'Issue'")
            .joins("join custom_fields cf4 on cf4.id = cv4.custom_field_id and cf4.name = '#{TeamDashboardConstants::BELTECH_PM_FIELD_NAME}'")
            .joins('join users u on u.id = issues.assigned_to_id')
            .joins('join members m on m.user_id = u.id')
            .joins('join member_roles mr on mr.member_id = m.id')
            .joins('join roles r on r.id = mr.role_id')
            .where("(r.name = '#{TeamDashboardConstants::BELTECH_PROGRAMMER_ROLE_NAME}' and cv4.value != '')")
            .group('issues.id')
        selected_issue_ids.push(issues[group_code].map(&:id)).flatten!
      else
        issues[group_code] =
          all_issues
            .where('issues.id not in (?)', selected_issue_ids.any? ? selected_issue_ids: [''])
      end
    end

    issues
  end

  def owner_instance(user)
    user.is_qa_member?(@qa_owner_field) ? @qa_owner_field : @technical_owner_field
  end

  def story_points(issues)
    issues.sum(:story_points)
  end

  def external_points(issues)
    issues.sum('cv.value').to_i
  end

  def story_point(issue)
    issue.try(:story_points)
  end

  def external_priority(issue)
    (/\A[-+]?\d+\z/) === issue.external_priority ? issue.external_priority : nil
  end

  def points_content_tag(issue, tag, options)
    if issue.tracker.name == 'Bug'
      points = external_priority(issue)
      title = {title: 'External Points'}
    else
      points = story_point(issue)
      title = {title: 'Story Points'}
    end
    if points
      options.merge!(title)
    else
      points = TeamDashboardConstants::EMPTY_POINTS_SYMBOL
    end

    content_tag(tag, points, options)
  end

  def get_color_class(issue)
    TeamDashboardConstants::SUPPORT_TICKET_PRIORITY_COLORS[issue.priority.name.to_sym]
  end

  def get_issue_attributes(issue)
    attributes = []

    attributes << { caption: 'Status', value: issue.status }
    attributes << { caption: 'Priority', value: issue.priority }
    attributes << { caption: 'Assignee', value: issue.assigned_to }
    attributes << { caption: 'Beltech PM', value: issue.beltech_pm }
    attributes << { caption: 'Support Analyst', value: issue[:support_analyst] }
    attributes << { caption: 'Escalated to tier 3 time', value: "#{issue[:esc_tier_3_time]} (#{time_ago_in_words(issue[:esc_tier_3_time].to_time)} ago)" }

    attributes
  end

end
