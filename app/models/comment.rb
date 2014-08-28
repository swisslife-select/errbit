class Comment < ActiveRecord::Base
  include Authority::Abilities

  belongs_to :problem
  belongs_to :user

  counter_culture :problem

  delegate   :app, :to => :problem

  validates_presence_of :body

  def notification_recipients
    app.error_recipients - [user.email]
  end

  def emailable?
    app.emailable? && notification_recipients.any?
  end
end
