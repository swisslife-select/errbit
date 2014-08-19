class NoticeNotificationServiceWorker
  include Sidekiq::Worker

  def perform(notice_id)
    notice = Notice.find(notice_id)
    notice.app.notification_service.create_notification(notice.problem)
  end
end
