class CommentObserver < ActiveRecord::Observer
  def after_create(comment)
    comment.execute_after_commit do
      Mailer.comment_notification(self).deliver if comment.emailable?
    end
  end
end
