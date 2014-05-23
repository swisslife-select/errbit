class NoticeObserver < ActiveRecord::Observer
  observe :notice

  def after_commit(object)
    after_commit_on_create(object) if object.send(:transaction_include_any_action?, [:create])
  end

  def after_commit_on_create(notice)
    NoticeNotificationWorker.perform_async notice.id if notice.should_email?

    #TODO: move to worker and fix notice_observer_spec
    notice.app.notification_service.create_notification(notice.problem) if notice.should_notify?
  end
end
