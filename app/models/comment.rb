class Comment < ActiveRecord::Base
  include Authority::Abilities

  after_create :deliver_email, :if => :emailable?

  belongs_to :problem
  belongs_to :user

  counter_culture :problem

  delegate   :app, :to => :problem

  validates_presence_of :body

  def deliver_email
    Mailer.comment_notification(self).deliver
  end

  def notification_recipients
    app.error_recipients - [user.email]
  end

  def emailable?
    app.emailable? && notification_recipients.any?
  end
end
