module AppsHelper
  def link_to_copy_attributes_from_other_app
    if App.count > 1
      html =  link_to('copy settings from another app', '#',
                       :class => 'button copy_config')
      html << select("duplicate", "app",
                     App.order('name ASC').reject{|a| a == @app }.
                     collect{|p| [ p.name, p.id ] }, {:include_blank => "[choose app]"},
                     {:class => "choose_other_app", :style => "display: none;"})
      return html
    end
  end

  def any_repo_urls?
    detect_any_apps_with_attributes if @any_repo_urls.nil?
    @any_repo_urls
  end

  def any_notification_services?
    detect_any_apps_with_attributes if @any_notification_services.present?
    @any_notification_services
  end

  def any_issue_trackers?
    detect_any_apps_with_attributes if @any_issue_trackers.nil?
    @any_issue_trackers
  end

  def any_deploys?
    detect_any_apps_with_attributes if @any_deploys.nil?
    @any_deploys
  end

  def need_display_notify_all_users_field?
    Errbit::Config.try :display_notify_all_users_field
  end

  private

  def detect_any_apps_with_attributes
    @any_repo_urls = @any_issue_trackers = @any_deploys = @any_notification_services = false

    @apps.each do |app|
      @any_repo_urls ||= app.repo_url?
      @any_issue_trackers ||= app.issue_tracker_configured?
      @any_deploys        ||= !!app.last_deploy_at
      @any_notification_services ||= app.notification_service_configured?
    end
  end
end
