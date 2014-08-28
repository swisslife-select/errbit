class NoticeObserver < ActiveRecord::Observer
  def after_create(notice)
    # for correct after_commit callbacks priority
    notice.execute_after_commit do
      # reread problem.notices_count
      notice.reload
      NoticeNotificationWorker.perform_async notice.id if notice.should_email?
      NoticeNotificationServiceWorker.perform_async notice.id if notice.should_notify?
    end
  end
end
