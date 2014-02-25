class NoticeObserver < ActiveRecord::Observer
  observe :notice

  def after_commit(object)
    after_commit_on_create(object) if object.send(:transaction_include_action?, :create)
  end


  def after_commit_on_create(notice)
    Mailer.err_notification(notice).deliver if notice.should_email?
    notice.app.notification_service.create_notification(notice.problem) if notice.should_notify?
  rescue => e
    Airbrake.notify(e)
  end
end
