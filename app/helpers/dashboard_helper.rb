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
    params = []
    params << 'set_filter=1&sort=priority:desc,id&group_by=&t[]='
    params << 'c[]=project&c[]=tracker&c[]=status&c[]=priority&c[]=subject&c[]=assigned_to&c[]=updated_on&c[]=cf_77'
    params << 'op[status_id]=*&op[cf_77]=='
    params << 'f[]=status_id&f[]=cf_77&f[]='
    params << "utf8=✓&v[cf_77][]=#{user.id}"
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
    owner_field = user.is_qa_member?(@qa_owner_field) ? @qa_owner_field : @technical_owner_field

    value = owner_field.field_format == 'user' ? user.id : user.name

    issues =
      Issue.select('issues.*, ad.story_points, cv.value AS `external_priority`').visible
        .joins("INNER JOIN custom_values cf ON cf.customized_id = issues.id AND customized_type = 'Issue'
               AND custom_field_id = #{owner_field.id} AND value = '#{value}'")
        .joins("JOIN custom_fields cuf ON cuf.name = '#{TeamDashboardConstants::EXTERNAL_PRIORITY_FIELD_NAME}'")
        .joins('LEFT JOIN custom_values cv ON cv.customized_id = issues.id AND cv.custom_field_id = cuf.id')
        .joins('LEFT JOIN agile_data ad ON ad.issue_id = issues.id')
        .where(fixed_version_id: @selected_version_id)

    @ticket_status ? issues.open : issues
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

end
