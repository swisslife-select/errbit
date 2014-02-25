class NoticeNotificationWorker
  include Sidekiq::Worker

  def perform(notice_id)
    notice = Notice.find(notice_id)
    Mailer.err_notification(notice).deliver
  end
end
